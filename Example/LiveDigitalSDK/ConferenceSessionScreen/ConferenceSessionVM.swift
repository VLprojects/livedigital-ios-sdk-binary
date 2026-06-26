import Foundation
import LiveDigitalSDK
import UIKit.UIDevice
import Combine


@MainActor
final class ConferenceSessionVM: ObservableObject {
	private enum Config {
		static let reconnectInterval: TimeInterval = 3
	}

	@Published var isSoundOn = true
	@Published var isMicrophoneOn: Bool
	@Published var canFinishSession = false
	@Published var roomName: String
	@Published var callStatusLabel: String
	@Published var isInCall: Bool

	weak var coordinator: ConferenceScreenCoordinator?

	@Published private var callStatus: CallSessionStatus {
		didSet {
			handleStatusChange()
		}
	}

	private let apiClient: MoodhoodAPIClient
	private let room: Room
	private let engine: LiveDigitalEngine
	private let clientUniqueId: String = UUID().uuidString
	private var channelSession: ChannelSession?
	private var audioSource: AudioSource?
	private var participantId: String?
	private var peers = [PeerId: Peer]()
	private var currentRouteKind: AudioRoute.Kind?
	private var reconnectTimer: Timer?
	private var callDurationTimerCancellable: AnyCancellable?

	init(apiClient: MoodhoodAPIClient, room: Room) {
		self.apiClient = apiClient
		self.room = room
		self.isMicrophoneOn = true
		self.roomName = room.name

		let callStatus: CallSessionStatus = .disconnected
		self.callStatus = callStatus
		self.callStatusLabel = Self.callStatusText(for: callStatus)
		self.isInCall = Self.isInCall(for: callStatus)

		let engine = StockLiveDigitalEngine(
			environment: .production,
			clientUniqueId: LiveDigitalSDK.ClientUniqueId(rawValue: clientUniqueId),
			useCallKitAudio: false
		)
		self.engine = engine
		engine.delegate = self

		updateLoggerMeta()
		bindCallStatus()
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
			callStatus = .disconnecting
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
		callStatus = .disconnected
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
		callStatus = .connecting

		Task {
			if !apiClient.isAuthorized {
				try await apiClient.authorizeAsGuest()
			}

			let participant = try await apiClient.createParticipant(
				space: room.spaceId,
				room: room.id,
				clientUniqueId: clientUniqueId,
				role: "host",
				name: UIDevice.current.name
			)
			print("Created participant: \(participant)")

			let signalingToken = try await apiClient.createSignalingToken(
				space: room.spaceId,
				participant: participant.id
			)
			print("Created signaling token: \(signalingToken)")

			self.participantId = participant.id

			self.startConferenceSession(
				channelId: ChannelId(rawValue: room.channelId),
				peerId: PeerId(rawValue: participant.id),
				signalingToken: signalingToken.signalingToken
			)
		}
	}

	func startConferenceSession(
		channelId: ChannelId,
		peerId: PeerId,
		signalingToken: String
	) {
		callStatus = .connecting

		engine.connectToChannel(
			channelId,
			mediaRole: .host,
			signalingToken: signalingToken,
			peerId: peerId,
			peerPayload: [
				"name": UIDevice.current.name
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
					self.callStatus = .connected(.now)
				case let .failure(error):
					print("Failed to start session with error: \(error)")
					self.callStatus = .disconnected
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

	static func callStatusText(for status: CallSessionStatus) -> String {
		switch status {
			case .dialing: String(localized: .callStatusDialing)
			case .connecting: String(localized: .callStatusConnecting)
			case .connected(let callStart): callDurationText(Date.now.timeIntervalSince(callStart))
			case .disconnecting: String(localized: .callStatusDisconnecting)
			case .disconnected: String(localized: .callStatusDisconnected)
			case .callEnded: String(localized: .callStatusEnded)
		}
	}

	static func isInCall(for status: CallSessionStatus) -> Bool {
		switch status {
			case .dialing: false
			case .connecting: true
			case .connected: true
			case .disconnecting: true
			case .disconnected: true
			case .callEnded: false
		}
	}

	static func callDurationText(_ duration: TimeInterval) -> String {
		let seconds = Int(duration.rounded(.awayFromZero))
		let h = seconds / 3600
		let m = (seconds % 3600) / 60
		let s = seconds % 60
		if h > 0 {
			return String(format: "%d:%02d:%02d", h, m, s)
		} else {
			return String(format: "%02d:%02d", m, s)
		}
	}

	func handleStatusChange() {
		switch callStatus {
			case .connected(let startDate):
				startTimer(from: startDate)
			case .connecting, .disconnecting, .disconnected, .dialing, .callEnded:
				stopTimer()
		}
	}

	func startTimer(from startDate: Date) {
		callDurationTimerCancellable?.cancel()

		callDurationTimerCancellable = Timer
			.publish(every: 1, on: .main, in: .common)
			.autoconnect()
			.map { _ in Date().timeIntervalSince(startDate) }
			.sink { [weak self] elapsed in
				guard let self else { return }
				self.callStatusLabel = Self.callDurationText(elapsed)
			}
	}

	func stopTimer() {
		callDurationTimerCancellable?.cancel()
		callDurationTimerCancellable = nil
	}

	func bindCallStatus() {
		$callStatus
			.map { Self.callStatusText(for: $0) }
			.assign(to: &$callStatusLabel)
		$callStatus
			.map { Self.isInCall(for: $0) }
			.assign(to: &$isInCall)
	}
}
