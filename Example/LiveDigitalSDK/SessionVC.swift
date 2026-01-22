import UIKit
import LiveDigitalSDK
import AVFoundation


final class SessionVC: UIViewController {
	private struct Constants {
		static let moodhoodAPIHost = URL(string: "https://moodhood-api.livedigital.space")!
		static let moodhoodClientId = "moodhood-demo"
		static let moodhoodClientSecret = "demo12345abcde6789zxcvDemo"
	}

	var spaceId: String? {
		didSet {
			updateLoggerMeta()
		}
	}

	var roomId: String? {
		didSet {
			updateLoggerMeta()
		}
	}

	@IBOutlet var localPreviewShadowView: UIView!
	@IBOutlet var localPreviewContainer: UIView!
	@IBOutlet var buttonsContainer: UIView!
	@IBOutlet var localAudioButton: UIButton!
	@IBOutlet var localVideoButton: UIButton!
	@IBOutlet var peersViewsScroller: UIScrollView!
	@IBOutlet var peersViewsContainer: UIStackView!
	@IBOutlet var finishButton: UIButton!
	private var peerViews = [PeerId: PeerView]()
	private var peers = [PeerId: Peer]()

	private let clientUniqueId: String = UUID().uuidString
	private let apiClient: MoodhoodAPIClient
	private let engine: LiveDigitalEngine
	private var channelSession: ChannelSession?
	private var videoSource: VideoSource?
	private var audioSource: AudioSource?

	private var userToken: MoodhoodUserToken?
	private var participantId: String?

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		let engine = StockLiveDigitalEngine(
			environment: .production,
			clientUniqueId: LiveDigitalSDK.ClientUniqueId(rawValue: clientUniqueId)
		)
		self.engine = engine

		let apiEnvironment = MoodhoodAPIEnvironment(
			apiHost: Constants.moodhoodAPIHost,
			clientId: Constants.moodhoodClientId,
			clientSecret: Constants.moodhoodClientSecret
		)
		self.apiClient = StockMoodhoodAPIClient(environment: apiEnvironment)

		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		engine.delegate = self
	}

	required init?(coder: NSCoder) {
		let engine = StockLiveDigitalEngine(
			environment: .production,
			clientUniqueId: LiveDigitalSDK.ClientUniqueId(rawValue: clientUniqueId)
		)
		self.engine = engine

		let apiEnvironment = MoodhoodAPIEnvironment(
			apiHost: Constants.moodhoodAPIHost,
			clientId: Constants.moodhoodClientId,
			clientSecret: Constants.moodhoodClientSecret
		)
		self.apiClient = StockMoodhoodAPIClient(environment: apiEnvironment)

		super.init(coder: coder)

		engine.delegate = self
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		localPreviewShadowView.layer.shadowPath =
			UIBezierPath(roundedRect: localPreviewContainer.bounds, cornerRadius: 8).cgPath
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		print("LiveDigitalSDK version: \(LiveDigital.version())")

		finishButton.layer.masksToBounds = true
		finishButton.layer.cornerRadius = 20
		finishButton.backgroundColor = .systemRed

		buttonsContainer.layer.masksToBounds = true
		buttonsContainer.layer.cornerRadius = 20

		localPreviewContainer.layer.masksToBounds = true
		localPreviewContainer.layer.cornerRadius = 8

		localPreviewShadowView.layer.shadowOpacity = 0.5
		localPreviewShadowView.layer.shadowColor = UIColor.black.cgColor
		localPreviewShadowView.layer.shadowRadius = 12

		view.backgroundColor = .systemBackground
		localPreviewShadowView.backgroundColor = .clear
		localPreviewContainer.backgroundColor = .secondarySystemBackground

		let menuInteraction = UIContextMenuInteraction(delegate: self)
		localAudioButton.addInteraction(menuInteraction)

		AVCaptureDevice.requestAccess(for: .audio) { granted in
			AVCaptureDevice.requestAccess(for: .video) { granted in
				DispatchQueue.main.async {
					self.startConferenceSession()
				}
			}
		}
	}
}

// MARK: - LiveDigitalSessionManagerDelegate implementation

extension SessionVC: LiveDigitalSessionManagerDelegate {
}

// MARK: - CameraManagerDelegate implementation

extension SessionVC: CameraManagerDelegate {
	func cameraManagerFailed(cameraManager: CameraManager, error: MediaCapturerError) {
		print("\(cameraManager) failed with error \(error)")
	}

	func cameraManagerSwitchedCamera(cameraManager: CameraManager, to position: AVCaptureDevice.Position?) {
	}
}

// MARK: - AudioRouterDelegate implementation

extension SessionVC: AudioRouterDelegate {
	func needRestartAudio() {
	}

	func routesChanged(in audioRouter: AudioRouter) {
	}
}

// MARK: - ChannelSessionObserver implementation

extension SessionVC: ChannelSessionObserver {
	func channelSessionJoinedChannel(_ channelSession: any LiveDigitalSDK.ChannelSession) {
		guard let participantId, let userToken, let spaceId, let roomId else {
			print("Failed to join room: missing participantId or userToken")
			return
		}

		Task {
			do {
				try await apiClient.joinRoom(
					userToken: userToken,
					space: spaceId,
					room: roomId,
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

			let peerView: PeerView
			if let existingPeerView = peerViews[peer.id] {
				peerView = existingPeerView
			} else if let newPeerView = Bundle(for: PeerView.self)
				.loadNibNamed(String(describing: PeerView.self), owner: nil, options: nil)![0] as? PeerView {

				peerViews[peer.id] = newPeerView
				peersViewsContainer.addArrangedSubview(newPeerView)
				newPeerView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
				newPeerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
				peerView = newPeerView
			} else {
				assertionFailure("Failed to load PeerView from xib")
				return
			}

			peerView.update(audioIsActive: peer.producing(.microphone))
			peerView.update(videoView: nil, trackLabel: .camera)
			peerView.update(videoIsActive: peer.producing(.camera))
			peerView.update(name: peer.payload?["name"] as? String)
		}
	}

	func peersDisconnected(_ peerIds: Set<PeerId>) {
		for peerId in peerIds {
			peers[peerId] = nil
			guard let peerView = peerViews[peerId] else {
				return
			}

			peerViews[peerId] = nil
			peerView.removeFromSuperview()
		}
		updateVisiblePeersVideos()
	}

	func peerAddedVideoTrack(peer: Peer, trackLabel: TrackLabel, paused: Bool) {
		print("Peer \(peer) added video track \(trackLabel), paused: \(paused)")
	}

	func peerAddedVideoView(peer: Peer, videoView: UIView, trackLabel: TrackLabel, paused: Bool) {
		print("Peer \(peer) added video view \(trackLabel), paused: \(paused)")
		peerView(for: peer, trackLabel: trackLabel)?.update(videoView: videoView, trackLabel: trackLabel)
	}

	func peerStartedVideo(peer: Peer, trackLabel: TrackLabel) {
		print("Peer \(peer) started video \(trackLabel)")
		peerView(for: peer, trackLabel: trackLabel)?.update(videoIsActive: true)
	}

	func peerStoppedVideo(peer: Peer, trackLabel: TrackLabel) {
		peerView(for: peer, trackLabel: trackLabel)?.update(videoIsActive: false)
	}

	func peerStartedAudio(peer: Peer, trackLabel: TrackLabel) {
		peerView(for: peer, trackLabel: trackLabel)?.update(audioIsActive: true)
	}

	func peerStoppedAudio(peer: Peer, trackLabel: TrackLabel) {
		peerView(for: peer, trackLabel: trackLabel)?.update(audioIsActive: false)
	}

	func gotPeerAppDataUpdates(_ updates: [PeerAppData]) {
		for update in updates {
			guard let peerView = peerViews[update.peerId] else {
				continue
			}
			peerView.update(name: update.appData["name"] as? String)
		}
	}

	func channelSessionStoppedByServer(_ channelSession: ChannelSession) {
		if let videoSource {
			engine.stopVideoSource(videoSource)
		}
		if let audioSource {
			engine.stopAudioSource(audioSource)
		}
		finishButton.isEnabled = false
		channelSession.stop(completion: { [weak self] in
			self?.dismiss(animated: true)
		})
	}
}

// MARK: - ChannelSessionDelegate implementation

extension SessionVC: ChannelSessionDelegate {
	func sessionNeedsRestart(_ channelSession: ChannelSession) {
		self.channelSession?.start(
			mediaRole: .host,
			participantId: nil,
			signalingToken: nil,
			peerId: nil,
			peerPayload: [
				"name": UIDevice.current.name
			]
		)
	}

	func channelSessionShouldSuspendVideo(_ channelSession: ChannelSession,
		with trackLabel: TrackLabel, from peer: Peer) -> Bool {

		guard let peerView = peerView(for: peer, trackLabel: trackLabel) else {
			return true
		}
		peerView.videoSuspended = !isPeerViewVisible(peerView)
		return peerView.videoSuspended
	}

	func channelSessionShouldSuspendAudio(_ channelSession: ChannelSession,
		with trackLabel: TrackLabel, from peer: Peer) -> Bool {

		return false
	}
}

// MARK: - Private methods
private extension SessionVC {
	func updateLoggerMeta() {
		if let roomId {
			engine.logger.addMeta(["roomId": roomId])
		}
		if let spaceId {
			engine.logger.addMeta(["spaceId": spaceId])
		}
	}

	func startConferenceSession() {
		updateLocalVideoEnabled(false)
		updateLocalAudioEnabled(false)

		guard let spaceId, let roomId else {
			print("Skip session start: spaceId or roomId is not specified")
			return
		}

		Task {
			let userToken = try await apiClient.authorizeAsGuest()
			print("Created user token: \(userToken)")

			let room = try await apiClient.fetchRoom(userToken: userToken, space: spaceId, room: roomId)
			print("Fetched room details: \(room)")

			let participant = try await apiClient.createParticipant(
				userToken: userToken,
				space: spaceId,
				room: roomId,
				clientUniqueId: clientUniqueId,
				role: "host",
				name: UIDevice.current.name
			)
			print("Created participant: \(participant)")

			let signalingToken = try await apiClient.createSignalingToken(
				userToken: userToken,
				space: spaceId,
				participant: participant.id
			)
			print("Created signaling token: \(signalingToken)")

			await MainActor.run {
				self.userToken = userToken
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
				videoSource.localVideoView.translatesAutoresizingMaskIntoConstraints = false
				localPreviewContainer.addSubview(videoSource.localVideoView)
				localPreviewContainer.leftAnchor
					.constraint(equalTo: videoSource.localVideoView.leftAnchor)
					.isActive = true
				localPreviewContainer.rightAnchor
					.constraint(equalTo: videoSource.localVideoView.rightAnchor)
					.isActive = true
				localPreviewContainer.topAnchor
					.constraint(equalTo: videoSource.localVideoView.topAnchor)
					.isActive = true
				localPreviewContainer.bottomAnchor
					.constraint(equalTo: videoSource.localVideoView.bottomAnchor)
					.isActive = true
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

	func peerView(for peer: Peer, trackLabel: TrackLabel) -> PeerView? {
		if peerViews[peer.id] == nil {
			print("Requesting view for unknown peer \(peer)")
			peersJoined([peer])
		}

		// TODO: Implement support for several videos from one peer.
		return peerViews[peer.id]
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
			updateVideoButtonState(isOn: false)
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
		updateVideoButtonState(isOn: enabled)
	}

	func updateLocalAudioEnabled(_ enabled: Bool) {
		if enabled, audioSource == nil {
			startAudioSource()
		}
		guard let session = channelSession, let source = audioSource else {
			print("Failed to update local audio state: channel or audio source is undefined.")
			updateAudioButtonState(isOn: false)
			return
		}

		if enabled {
			session.addAudioSource(source)
		} else {
			session.removeAudioSource(source)
			engine.stopAudioSource(source)
			audioSource = nil
		}
		updateAudioButtonState(isOn: enabled)
	}

	func updateAudioButtonState(isOn: Bool) {
		localAudioButton.isSelected = isOn
		localAudioButton.tintColor = isOn ? .systemRed : .systemGray
	}

	func updateVideoButtonState(isOn: Bool) {
		localVideoButton.isSelected = isOn
		localVideoButton.tintColor = isOn ? .systemRed : .systemGray
	}

	func localAudioContextMenu() -> UIContextMenuConfiguration {
		let routes = engine.audioRouter.availableRoutes
		let currentRoute = engine.audioRouter.currentRoute

		let menuConfig = UIContextMenuConfiguration(identifier: nil, previewProvider: nil,
			actionProvider: { _ in
				let actions: [UIAction] = routes.map { route in
						let isSelected = route == currentRoute
						let title: String
						switch route.kind {
							case .internalEarSpeaker:
								title = "iPhone"
							case .internalLoudspeaker:
								title = "Loudspeaker"
							case .headset:
								title = "Headset"
							case .muted:
								title = "Mute"
							case let .bluetoothHeadset(routeTitle):
								title = routeTitle
							case let .bluetooth(routeTitle):
								title = routeTitle
							case let .external(routeTitle):
								title = routeTitle
							case .noAudio:
								title = "No audio"
						}
						return UIAction(title: title, state: isSelected ? .on : .off,
						handler: { [weak self] _ in
								self?.engine.audioRouter.updatePreferred(route: route)
							})
					}

				return UIMenu(title: "Select audio device", children: actions)
			})

		return menuConfig
	}

	func updateVisiblePeersVideos() {
		for (peerId, peerView) in self.peerViews {
			guard let peer = peers[peerId], let trackLabel = peerView.trackLabel else {
				continue
			}

			let shouldBeSuspended = !isPeerViewVisible(peerView)
			if shouldBeSuspended != peerView.videoSuspended {
				peerView.videoSuspended = shouldBeSuspended
				if shouldBeSuspended {
					channelSession?.suspendVideo(with: trackLabel, for: peer)
				} else {
					channelSession?.proceedVideo(with: trackLabel, for: peer)
				}
			}
		}
	}

	func isPeerViewVisible(_ view: PeerView) -> Bool {
		let visibleArea = CGRect(origin: peersViewsScroller.contentOffset, size: peersViewsScroller.frame.size)
		let viewFrameInScroll = view.superview?.convert(view.frame, to: peersViewsScroller)
		return viewFrameInScroll?.intersects(visibleArea) ?? false
	}
}

// MARK: - UI Actions

private extension SessionVC {
	@IBAction
	func toggleMicrophoneEnabled(_ sender: UIButton) {
		updateLocalAudioEnabled(!sender.isSelected)
	}

	@IBAction
	func toggleCameraEnabled(_ sender: UIButton) {
		updateLocalVideoEnabled(!sender.isSelected)
	}

	@IBAction
	func toggleCamera(_ sender: UISwipeGestureRecognizer) {
		if case let .failure(error) = engine.cameraManager.flipCamera() {
			print("Failed to flip camera: \(error)")
		}
	}

	@IBAction
	func finishSession(_ sender: UIButton) {
		if let videoSource {
			engine.stopVideoSource(videoSource)
		}
		if let audioSource {
			engine.stopAudioSource(audioSource)
		}

		guard let channelSession else {
			dismiss(animated: true)
			return
		}
		finishButton.isEnabled = false
		channelSession.stop(completion: { [weak self] in
			self?.dismiss(animated: true)
		})
	}
}

// MARK: - UIScrollViewDelegate implementation

extension SessionVC: UIScrollViewDelegate {
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		updateVisiblePeersVideos()
	}

	func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		updateVisiblePeersVideos()
	}
}

// MARK: - UIContextMenuInteractionDelegate implementation

extension SessionVC: UIContextMenuInteractionDelegate {
	func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
		configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

		if interaction.view == localAudioButton {
			return localAudioContextMenu()
		} else {
			return nil
		}
	}
}
