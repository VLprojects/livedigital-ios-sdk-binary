import Foundation
import LiveDigitalSDK
import Combine


@MainActor
final class ConferenceSessionVM: ObservableObject {
	private enum Config {
		static let reconnectInterval: TimeInterval = 3
	}

	@Published private(set) var isSoundOn = true
	@Published private(set) var isMicrophoneOn: Bool
	@Published private(set) var canFinishSession = false
	@Published private(set) var roomName: String
	@Published private(set) var callStatusLabel = String()
	@Published private(set) var isInCall = false

	weak var coordinator: ConferenceScreenCoordinator?

	private let apiClient: MoodhoodAPIClient
	private let room: Room
	private let engine: LiveDigitalEngine
	private let deviceEnvironment = DeviceEnvironmentProvider.environment
	private var channelSession: ChannelSession?
	private var audioSource: AudioSource?
	private var participantId: String?
	private var peers = [PeerId: Peer]()
	private var currentRouteKind: AudioRoute.Kind?
	private var reconnectTimer: Timer?
	private let callDurationTimer = CallDurationTimer()

	init(apiClient: MoodhoodAPIClient, room: Room) {
		self.apiClient = apiClient
		self.room = room
		self.isMicrophoneOn = true
		self.roomName = room.name
		self.callDurationTimer.callStatus = .disconnected

		let engine = StockLiveDigitalEngine(
			environment: .production,
			clientUniqueId: LiveDigitalSDK.ClientUniqueId(rawValue: deviceEnvironment.deviceId),
			useCallKitAudio: false
		)
		self.engine = engine
		engine.delegate = self

		updateLoggerMeta()
		callDurationTimer.$callStatusLabel.assign(to: &$callStatusLabel)
		callDurationTimer.$isInCall.assign(to: &$isInCall)
		startConferenceSession()
	}

	deinit {
		reconnectTimer?.invalidate()
	}
}

// MARK: - Internal methods

internal extension ConferenceSessionVM {
	func dismiss() {
		coordinator?.dismissCallScreen()
	}

	func toggleMicrophone() {
		updateLocalAudioEnabled(!isMicrophoneOn)
	}

	func updatePreferred(route: AudioRoute) {
		engine.audioRouter.updatePreferred(route: route)
	}

	func finishSession() {
		if let audioSource {
			engine.stopAudioSource(audioSource)
			self.audioSource = nil
		}

		if let channelSession {
			canFinishSession = false
			callDurationTimer.callStatus = .disconnecting
			channelSession.stop(completion: { [weak self] in
				self?.endSession()
			})
		} else {
			endSession()
		}
	}
}

// MARK: - AudioRouterDelegate implementation

extension ConferenceSessionVM: @MainActor AudioRouterDelegate {
	func needRestartAudio() {
	}

	func routesChanged(in audioRouter: AudioRouter) {
		let availableRoutes = audioRouter.availableRoutes
		let currentRoute = audioRouter.currentRoute
		print("Routes changed: \(availableRoutes), current: \(currentRoute)")

		if currentRoute.kind == .noAudio {
			print("Route changed to \(currentRoute), probably during a call or timer alert")
			// Avoid re-assigning audio route during system alert. It can cause an infinite recursion.
			return
		}

		self.currentRouteKind = currentRoute.kind
	}
}

// MARK: - ChannelSessionDelegate implementation

extension ConferenceSessionVM: @MainActor ChannelSessionDelegate {
	func sessionNeedsRestart(_ channelSession: ChannelSession) {
		let sessionIsRunning = switch channelSession.status {
			case .starting, .started, .restarting: true
			case .stopping, .stopped: false
			@unknown default: true
		}
		guard !sessionIsRunning else {
			print("Will stop running session during reconnect flow...")
			channelSession.stop { [weak self] in
				print("Will start a new session as new participant during reconnect flow...")
				self?.startConferenceSession()
			}
			return
		}

		print("Will start a new session as new participant during reconnect flow...")
		self.startConferenceSession()
	}

	func channelSessionShouldSuspendVideo(
		_ channelSession: ChannelSession,
		with trackLabel: TrackLabel,
		from peer: Peer
	) -> Bool {
		// In audio call we don't need to decode incoming video.
		return true
	}

	func channelSessionShouldSuspendAudio(
		_ channelSession: ChannelSession,
		with trackLabel: TrackLabel,
		from peer: Peer
	) -> Bool {
		// In audio call we enable all incoming audio.
		return false
	}
}

// MARK: - CameraManagerDelegate implementation

extension ConferenceSessionVM: CameraManagerDelegate {
}

// MARK: - ChannelSessionObserver implementation

extension ConferenceSessionVM: @MainActor ChannelSessionObserver {
	func channelSessionNeedsUpdateState(_ channelSession: any LiveDigitalSDK.ChannelSession) {
		// Session was recovered after connection loss.
		// Some events may have been missed.
		// You may want to refetch actual call/room state from applicaion server.
	}
}

// MARK: - Private methods

private extension ConferenceSessionVM {
	func updateLoggerMeta() {
		engine.logger.addMeta(["roomId": room.id])
		engine.logger.addMeta(["spaceId": room.spaceId])
	}

	func endSession() {
		channelSession = nil
		callDurationTimer.callStatus = .disconnected
		coordinator?.dismissCallScreen()
	}

	func scheduleReconnect() {
		reconnectTimer = .scheduledTimer(withTimeInterval: Config.reconnectInterval, repeats: false) { [weak self] _ in
			DispatchQueue.main.async {
				self?.reconnectTimer?.invalidate()
				self?.reconnectTimer = nil
				self?.startConferenceSession()
			}
		}
	}

	func updateLocalAudioEnabled(_ enabled: Bool) {
		isMicrophoneOn = enabled
		guard let channelSession else {
			return
		}

		if enabled, audioSource == nil {
			startAudioSource()
		}
		guard let audioSource else {
			print("Failed to update local audio state: channel or audio source is undefined.")
			isMicrophoneOn = false
			return
		}

		if enabled {
			channelSession.addAudioSource(audioSource)
		} else {
			channelSession.removeAudioSource(audioSource)
			engine.stopAudioSource(audioSource)
			self.audioSource = nil
		}
	}

	func startConferenceSession() {
		callDurationTimer.callStatus = .connecting

		Task {
			if !apiClient.isAuthorized {
				try await apiClient.authorizeAsGuest()
			}

			let participant = try await apiClient.createParticipant(
				space: room.spaceId,
				room: room.id,
				clientUniqueId: deviceEnvironment.deviceId,
				role: "host",
				name: deviceEnvironment.deviceName
			)
			print("Created participant: \(participant)")

			let signalingToken = try await apiClient.createSignalingToken(
				space: room.spaceId,
				participant: participant.id
			)
			print("Created signaling token: \(signalingToken)")

			self.participantId = participant.id

			self.startConferenceSession(signalingToken: signalingToken.signalingToken)
		}
	}

	func startConferenceSession(signalingToken: String) {
		callDurationTimer.callStatus = .connecting

		engine.connectToChannel(
			signalingToken: signalingToken,
			peerPayload: [
				"name": deviceEnvironment.deviceName
			],
			completion: { [weak self] result in
			guard let self = self else {
				return
			}

			switch result {
				case let .success(channelSession):
					self.channelSession = channelSession
					channelSession.subscribe(self)
					channelSession.delegate = self
					self.callDurationTimer.callStatus = .connected(.now)
				case let .failure(error):
					print("Failed to start session with error: \(error)")
					self.callDurationTimer.callStatus = .disconnected
					self.scheduleReconnect()
			}

			self.updateLocalAudioEnabled(isMicrophoneOn)
		})
	}

	func startAudioSource() {
		switch engine.startAudioSource() {
			case let .success(audioSource):
				self.audioSource = audioSource
			case let .failure(error):
				print("Failed to start audio source: \(error)")
		}
	}
}
