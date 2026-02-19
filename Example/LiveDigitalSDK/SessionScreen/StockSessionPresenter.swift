import Foundation
import UIKit
import AVFoundation
import LiveDigitalSDK


final class StockSessionPresenter {
	private enum Constants {
		static let preferredInternalRoutes: [AudioRoute.Kind] = [
			.internalLoudspeaker,
			.internalEarSpeaker,
			.muted,
			.noAudio,
		]
	}

	private weak var view: SessionView?
	private let callManager: CallManager?
	private let apiClient: MoodhoodAPIClient
	private let engine: LiveDigitalEngine
	private let clientUniqueId: String = UUID().uuidString
	private let room: Room
	private var channelSession: ChannelSession?
	private var videoSource: VideoSource?
	private var audioSource: AudioSource?
	private var participantId: String?
	private var call: Call?
	private var peers = [PeerId: Peer]()
	private var audioRouterInitialized = false
	private var currentRouteKind: AudioRoute.Kind?

	init(room: Room, apiClient: MoodhoodAPIClient, callManager: CallManager?, view: SessionView) {
		self.room = room
		self.apiClient = apiClient
		self.callManager = callManager
		self.view = view
		let engine = StockLiveDigitalEngine(
			environment: .production,
			clientUniqueId: LiveDigitalSDK.ClientUniqueId(rawValue: clientUniqueId)
		)
		self.engine = engine
		engine.delegate = self
		callManager?.addObserver(self)
		updateLoggerMeta()
	}

	deinit {
		callManager?.removeObserver(self)
	}
}

// MARK: - SessionPresenter implementation

extension StockSessionPresenter: SessionPresenter {
	var availableAudioRoutes: [AudioRoute] {
		engine.audioRouter.availableRoutes
	}

	var currentAudioRoute: AudioRoute {
		engine.audioRouter.currentRoute
	}

	func viewDidLoad() {
		AVCaptureDevice.requestAccess(for: .audio) { granted in
			AVCaptureDevice.requestAccess(for: .video) { granted in
				DispatchQueue.main.async {
					self.startConferenceSession()
				}
			}
		}
	}

	func updateLocalVideoEnabled(_ enabled: Bool) {
		if enabled, videoSource == nil {
			startVideoSource { [weak self] source in
				self?.videoSource = source
				self?.updateLocalVideoEnabled(enabled)
			}
			return
		}

		guard let session = channelSession, let source = videoSource else {
			print("Failed to update local video state: channel or video source is undefined.")
			view?.updateVideoButtonState(isOn: false)
			return
		}

		if enabled {
			session.addVideoSource(source)
		} else {
			session.removeVideoSource(source)
			engine.stopVideoSource(source)
			if let camSource = source as? VideoSourceWithPreview {
				camSource.localVideoView.removeFromSuperview()
			}
			videoSource = nil
		}
		view?.updateVideoButtonState(isOn: enabled)
	}

	func updateLocalAudioEnabled(_ enabled: Bool) {
		if enabled, audioSource == nil {
			startAudioSource()
		}
		guard let session = channelSession, let source = audioSource else {
			print("Failed to update local audio state: channel or audio source is undefined.")
			view?.updateAudioButtonState(isOn: false)
			return
		}

		if enabled {
			session.addAudioSource(source)
		} else {
			session.removeAudioSource(source)
			engine.stopAudioSource(source)
			audioSource = nil
		}
		view?.updateAudioButtonState(isOn: enabled)
	}

	func updatePreferred(route: AudioRoute) {
		engine.audioRouter.updatePreferred(route: route)
	}

	func updateVideoTrackVisible(peerId: PeerId, trackLabel: TrackLabel, isVisible: Bool) {
		guard let peer = peers[peerId] else {
			print("Failed to update track visibility for unknown peer \(peerId)")
			return
		}
		if isVisible {
			channelSession?.proceedVideo(with: trackLabel, for: peer)
		} else {
			channelSession?.suspendVideo(with: trackLabel, for: peer)
		}
	}

	func flipCamera() {
		if case let .failure(error) = engine.cameraManager.flipCamera() {
			print("Failed to flip camera: \(error)")
		}
	}

	func finishSession() {
		if let videoSource {
			engine.stopVideoSource(videoSource)
		}
		if let audioSource {
			engine.stopAudioSource(audioSource)
		}

		if let channelSession {
			view?.updateCanFinish(false)
			channelSession.stop(completion: { [weak self] in
				self?.endSession()
			})
		} else {
			endSession()
		}
	}
}

// MARK: - LiveDigitalSessionManagerDelegate implementation

extension StockSessionPresenter: LiveDigitalSessionManagerDelegate {
}

// MARK: - CameraManagerDelegate implementation

extension StockSessionPresenter: CameraManagerDelegate {
	func cameraManagerFailed(cameraManager: CameraManager, error: MediaCapturerError) {
		print("\(cameraManager) failed with error \(error)")
	}

	func cameraManagerSwitchedCamera(cameraManager: CameraManager, to position: AVCaptureDevice.Position?) {
	}
}

// MARK: - AudioRouterDelegate implementation

extension StockSessionPresenter: AudioRouterDelegate {
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

// MARK: - ChannelSessionObserver implementation

extension StockSessionPresenter: ChannelSessionObserver {
	func channelSessionJoinedChannel(_ channelSession: any LiveDigitalSDK.ChannelSession) {
		guard let participantId else {
			print("Failed to join room: missing participantId")
			return
		}

		Task {
			do {
				try await apiClient.joinRoom(
					space: room.spaceId,
					room: room.id,
					participant: participantId
				)
				print("Joined room")
			} catch {
				print("Failed to join room: \(error)")
			}
		}
	}

	func channelSessionNeedsUpdateState(_ channelSession: any LiveDigitalSDK.ChannelSession) {
		// Session was recovered after connection loss.
		// Some events may have been missed.
		// You may want to refetch actual call/room state from applicaion server.
	}
	
	func peersJoined(_ joinedPeers: [Peer]) {
		print("Peers joined: \(joinedPeers)")
		for peer in joinedPeers {
			peers[peer.id] = peer
			view?.addPeer(peer)
		}
	}

	func peersDisconnected(_ peerIds: Set<PeerId>) {
		for peerId in peerIds {
			peers.removeValue(forKey: peerId)
		}
		view?.removePeers(peerIds)
	}

	func peerAddedVideoTrack(peer: Peer, trackLabel: TrackLabel, paused: Bool) {
		assureKnownPeer(peer)
		print("Peer \(peer) added video track \(trackLabel), paused: \(paused)")
	}

	func peerAddedVideoView(peer: Peer, videoView: UIView, trackLabel: TrackLabel, paused: Bool) {
		print("Peer \(peer) added video view \(trackLabel), paused: \(paused)")
		assureKnownPeer(peer)
		view?.updateVideoView(videoView, for: peer, trackLabel: trackLabel)
	}

	func peerStartedVideo(peer: Peer, trackLabel: TrackLabel) {
		print("Peer \(peer) started video \(trackLabel)")
		assureKnownPeer(peer)
		view?.updateVideo(isActive: true, for: peer, trackLabel: trackLabel)
	}

	func peerStoppedVideo(peer: Peer, trackLabel: TrackLabel) {
		view?.updateVideo(isActive: false, for: peer, trackLabel: trackLabel)
	}

	func peerStartedAudio(peer: Peer, trackLabel: TrackLabel) {
		assureKnownPeer(peer)
		view?.updateAudio(isActive: true, for: peer, trackLabel: trackLabel)
	}

	func peerStoppedAudio(peer: Peer, trackLabel: TrackLabel) {
		view?.updateAudio(isActive: false, for: peer, trackLabel: trackLabel)
	}

	func gotPeerAppDataUpdates(_ updates: [PeerAppData]) {
		for update in updates {
			view?.updatePeerAppData(update.peerId, appData: update.appData)
		}
	}

	func channelSessionStoppedByServer(_ channelSession: ChannelSession) {
		finishSession()
	}
}

// MARK: - ChannelSessionDelegate implementation

extension StockSessionPresenter: ChannelSessionDelegate {
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
		guard let view else {
			return true
		}
		return view.isVideoTrackVisible(peer: peer, trackLabel: trackLabel)
	}

	func channelSessionShouldSuspendAudio(_ channelSession: ChannelSession,
		with trackLabel: TrackLabel, from peer: Peer) -> Bool {

		return false
	}
}

// MARK: - CallManagerObserver implementation

extension StockSessionPresenter: CallManagerObserver {
	func didEndCall(_ call: Call) {
		guard call.id == self.call?.id else {
			return
		}
		self.call = nil
		finishSession()
	}

	func didUpdateCallMuteState(_ call: Call) {
		guard call.id == self.call?.id else {
			return
		}
		self.call = call

		updateLocalAudioEnabled(!call.isMuted)
	}

	func didUpdateAudioSession(_ audioSession: AVAudioSession, active: Bool) {
		// TODO: Implement me!
	}
}

// MARK: - Private methods

private extension StockSessionPresenter {
	func updateLoggerMeta() {
		engine.logger.addMeta(["roomId": room.id])
		engine.logger.addMeta(["spaceId": room.spaceId])
	}

	func endSession() {
		if let call {
			callManager?.reportCallEnded(call)
		}
		view?.dismiss()
	}

	func startConferenceSession() {
		updateLocalVideoEnabled(false)

		if let call {
			updateLocalAudioEnabled(!call.isMuted)
		} else {
			updateLocalAudioEnabled(false)
		}

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

			await MainActor.run {
				self.participantId = participant.id

				self.startConferenceSession(
					channelId: ChannelId(value: room.channelId),
					participantId: ParticipantId(value: participant.id),
					peerId: PeerId(rawValue: participant.id),
					signalingToken: signalingToken.signalingToken
				)
			}
		}
	}

	func startConferenceSession(
		channelId: ChannelId,
		participantId: ParticipantId,
		peerId: PeerId,
		signalingToken: String
	) {
		updateLocalVideoEnabled(false)
		updateLocalAudioEnabled(false)

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
					channelSession.shouldShowLocalPeer = true
					channelSession.subscribe(self)
					channelSession.delegate = self
				case let .failure(error):
					print("Failed to start session with error: \(error)")
			}

			self.updateLocalVideoEnabled(self.videoSource != nil)
			self.updateLocalAudioEnabled(self.audioSource != nil)
		})
	}

	func startVideoSource(_ completion: ((VideoSource?)-> Void)) {
		switch engine.startVideoSource(position: .front) {
			case let .success(videoSource):
				view?.setupLocalPreview(videoSource.localVideoView)
				completion(videoSource)

			case let .failure(error):
				print("Failed to start video source: \(error)")
				completion(nil)
		}
	}

	func startAudioSource() {
		switch engine.startAudioSource() {
			case let .success(audioSource):
				self.audioSource = audioSource
			case let .failure(error):
				print("Failed to start audio source: \(error)")
		}
	}

	func assureKnownPeer(_ peer: Peer) {
		if peers[peer.id] == nil {
			peersJoined([peer])
		}
	}

	func selectDefaultAudioRoute() {
		let availableRoutes = engine.audioRouter.availableRoutes
		if let route = availableRoutes.first(where: { !Constants.preferredInternalRoutes.contains($0.kind) }) {
			engine.audioRouter.updatePreferred(route: route)
		} else {
			selectDefaultInternalAudioRoute()
		}
	}

	func selectDefaultInternalAudioRoute() {
		let availableRoutes = engine.audioRouter.availableRoutes
		// Constants.preferredInternalRoutes are ordered by its preference,
		// so look for a route from the top of internalRouteKinds.
		for kind in Constants.preferredInternalRoutes {
			if let route = availableRoutes.first(where: { $0.kind == kind }) {
				return engine.audioRouter.updatePreferred(route: route)
			} else {
				print("No route found for \(kind)")
			}
		}
		print("No internal audio routes found")
	}
}
