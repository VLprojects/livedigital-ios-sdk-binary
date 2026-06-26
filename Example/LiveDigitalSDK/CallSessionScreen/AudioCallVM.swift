import Foundation
import LiveDigitalSDK
import UIKit.UIDevice
import Combine


@MainActor
final class AudioCallVM: ObservableObject {
	private enum Config {
		static let reconnectInterval: TimeInterval = 3
	}

	@Published var isSoundOn = true
	@Published var isMicrophoneOn: Bool
	@Published var canFinishSession = false
	@Published var companionName: String
	@Published var callStatusLabel = String()
	@Published var isInCall = false
	@Published var canRedial: Bool

	weak var coordinator: CallScreenCoordinator?

	private let callManager: CallManager?
	private let apiClient: MoodhoodAPIClient
	private let room: Room
	private let engine: LiveDigitalEngine
	private let clientUniqueId: String = UUID().uuidString
	private var channelSession: ChannelSession?
	private var audioSource: AudioSource?
	private var participantId: String?
	private var call: Call
	private var peers = [PeerId: Peer]()
	private var currentRouteKind: AudioRoute.Kind?
	private var reconnectTimer: Timer?
	private var callDurationTimer = CallDurationTimer()

	init(callManager: CallManager?, apiClient: MoodhoodAPIClient, room: Room, call: Call) {
		self.callManager = callManager
		self.apiClient = apiClient
		self.room = room
		self.call = call
		self.isMicrophoneOn = !call.isMuted
		self.companionName = call.caller

		let callStatus: CallSessionStatus = .disconnected
		self.callDurationTimer.callStatus = callStatus
		self.canRedial = Self.canRedial(for: callStatus)

		let engine = StockLiveDigitalEngine(
			environment: .production,
			clientUniqueId: LiveDigitalSDK.ClientUniqueId(rawValue: clientUniqueId),
			useCallKitAudio: true
		)
		self.engine = engine
		engine.delegate = self

		updateLoggerMeta()

		callManager?.addObserver(self)

		bindCallStatus()

		switch call.direction {
			case .incoming:
				startConferenceSession()
			case .outgoing:
				self.callDurationTimer.callStatus = .dialing
		}
	}

	deinit {
		reconnectTimer?.invalidate()
	}
}

// MARK: - Internal methods

internal extension AudioCallVM {
	func redial() {
		coordinator?.redial(to: room)
	}

	func dismiss() {
		coordinator?.dismissCallScreen(call: call)
	}

	func toggleMicrophone() {
		// If we change microphone state directly, its state will be inconsistent with CallKit call state.
		// So we have to change CallKit mute state via callManager and wait for callback to actually toggle the mic.
		let newMutedState = audioSource != nil
		callManager?.toggleMicrophone(muted: newMutedState, in: call)
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

// MARK: - CallManagerObserver implementation

extension AudioCallVM: @MainActor CallManagerObserver {
	func didUpdateCallMuteState(_ call: Call) {
		guard call.id == self.call.id else {
			return
		}
		self.call = call
		updateLocalAudioEnabled(!call.isMuted)
	}

	func callWasAnswered(_ call: Call) {
		guard call.id == self.call.id, callDurationTimer.callStatus == .dialing else {
			return
		}
		self.call = call
		startConferenceSession()
	}

	func didEndCall(_ call: Call) {
		guard call.id == self.call.id else {
			return
		}
		self.call = call

		if let audioSource {
			engine.stopAudioSource(audioSource)
			self.audioSource = nil
		}

		if let channelSession {
			canFinishSession = false
			callDurationTimer.callStatus = .disconnecting
			channelSession.stop(completion: { [weak self] in
				self?.channelSession = nil
				self?.callDurationTimer.callStatus = .callEnded
			})
		} else {
			callDurationTimer.callStatus = .callEnded
		}
	}
}

// MARK: - AudioRouterDelegate implementation

extension AudioCallVM: @MainActor AudioRouterDelegate {
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

extension AudioCallVM: @MainActor ChannelSessionDelegate {
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

extension AudioCallVM: CameraManagerDelegate {
}

// MARK: - ChannelSessionObserver implementation

extension AudioCallVM: @MainActor ChannelSessionObserver {
	func channelSessionNeedsUpdateState(_ channelSession: any LiveDigitalSDK.ChannelSession) {
		// Session was recovered after connection loss.
		// Some events may have been missed.
		// You may want to refetch actual call/room state from applicaion server.
	}
}

// MARK: - Private methods

private extension AudioCallVM {
	func updateLoggerMeta() {
		engine.logger.addMeta(["roomId": room.id])
		engine.logger.addMeta(["spaceId": room.spaceId])
	}

	func endSession() {
		channelSession = nil
		callDurationTimer.callStatus = .disconnected
		callManager?.endCall(call)
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

	func startConferenceSession() {
		callDurationTimer.callStatus = .connecting

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
		callDurationTimer.callStatus = .connecting

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

	static func canRedial(for status: CallSessionStatus) -> Bool {
		switch status {
			case .callEnded: true
			case .dialing, .connecting, .connected, .disconnecting, .disconnected: false
		}
	}

	func bindCallStatus() {
		callDurationTimer.$callStatusLabel.assign(to: &$callStatusLabel)

		callDurationTimer.$isInCall.assign(to: &$isInCall)

		callDurationTimer.$callStatus
			.map { Self.canRedial(for: $0) }
			.assign(to: &$canRedial)
	}
}
