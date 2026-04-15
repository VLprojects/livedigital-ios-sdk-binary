import Foundation
import LiveDigitalSDK
import UIKit.UIDevice
import Combine


@MainActor
final class AudioCallVM: ObservableObject {
	private enum Config {
		static let reconnectInterval: TimeInterval = 3
		static let preferredInternalRoutes: [AudioRoute.Kind] = [
			.internalLoudspeaker,
			.internalEarSpeaker,
			.muted,
			.noAudio,
		]
	}

	@Published var isSoundOn = true
	@Published var isMicrophoneOn: Bool
	@Published var canFinishSession = false
	@Published var companionName: String
	@Published var callStatusLabel: String
	@Published var isInCall: Bool
	@Published var canRedial: Bool

	weak var coordinator: CallScreenCoordinator?

	@Published private var callStatus: CallSessionStatus {
		didSet {
			handleStatusChange()
		}
	}

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
	private var audioRouterInitialized = false
	private var currentRouteKind: AudioRoute.Kind?
	private var reconnectTimer: Timer?
	private var callDurationTimerCancellable: AnyCancellable?

	init(callManager: CallManager?, apiClient: MoodhoodAPIClient, room: Room, call: Call) {
		self.callManager = callManager
		self.apiClient = apiClient
		self.room = room
		self.call = call
		self.isMicrophoneOn = !call.isMuted
		self.companionName = call.caller

		let callStatus: CallSessionStatus = .disconnected
		self.callStatus = callStatus
		self.callStatusLabel = Self.callStatusText(for: callStatus)
		self.isInCall = Self.isInCall(for: callStatus)
		self.canRedial = Self.canRedial(for: callStatus)

		let engine = StockLiveDigitalEngine(
			environment: .production,
			clientUniqueId: LiveDigitalSDK.ClientUniqueId(rawValue: clientUniqueId)
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
				self.callStatus = .dialing
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
			callStatus = .disconnecting
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
		guard call.id == self.call.id, callStatus == .dialing else {
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
			callStatus = .disconnecting
			channelSession.stop(completion: { [weak self] in
				self?.channelSession = nil
				self?.callStatus = .callEnded
			})
		} else {
			self.callStatus = .callEnded
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

		// When user takes off his bluetooth headphones, but they are still connected,
		// system will switch the route automatically to internal speaker by default.
		// Internal speaker is hidden from routes list and activating it is not desired behaviour.
		// In this case we try switching to the loudspeaker (not back to headphones!).
		guard availableRoutes.contains(where: { $0.kind == currentRouteKind }) else {
			selectDefaultInternalAudioRoute()
			return
		}

		if !audioRouterInitialized {
			audioRouterInitialized = true
			selectDefaultAudioRoute()
		}
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
		return true
	}

	func channelSessionShouldSuspendAudio(
		_ channelSession: ChannelSession,
		with trackLabel: TrackLabel,
		from peer: Peer
	) -> Bool {
		return false
	}
}

// MARK: - CameraManagerDelegate implementation

extension AudioCallVM: CameraManagerDelegate {
}

// MARK: - LiveDigitalSessionManagerDelegate implementation

extension AudioCallVM: LiveDigitalSessionManagerDelegate {
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
		callStatus = .disconnected
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
				channelId: ChannelId(value: room.channelId),
				participantId: ParticipantId(value: participant.id),
				peerId: PeerId(rawValue: participant.id),
				signalingToken: signalingToken.signalingToken
			)
		}
	}

	func startConferenceSession(
		channelId: ChannelId,
		participantId: ParticipantId,
		peerId: PeerId,
		signalingToken: String
	) {
		callStatus = .connecting

		engine.connectToChannel(
			channelId,
			mediaRole: .host,
			participantId: participantId,
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

	func selectDefaultAudioRoute() {
		let availableRoutes = engine.audioRouter.availableRoutes
		if let route = availableRoutes.first(where: { !Config.preferredInternalRoutes.contains($0.kind) }) {
			engine.audioRouter.updatePreferred(route: route)
		} else {
			selectDefaultInternalAudioRoute()
		}
	}

	func selectDefaultInternalAudioRoute() {
		let availableRoutes = engine.audioRouter.availableRoutes
		// Constants.preferredInternalRoutes are ordered by its preference,
		// so look for a route from the top of internalRouteKinds.
		for kind in Config.preferredInternalRoutes {
			if let route = availableRoutes.first(where: { $0.kind == kind }) {
				return engine.audioRouter.updatePreferred(route: route)
			} else {
				print("No route found for \(kind)")
			}
		}
		print("No internal audio routes found")
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

	static func canRedial(for status: CallSessionStatus) -> Bool {
		switch status {
			case .callEnded: true
			case .dialing, .connecting, .connected, .disconnecting, .disconnected: false
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
		$callStatus
			.map { Self.canRedial(for: $0) }
			.assign(to: &$canRedial)
	}
}
