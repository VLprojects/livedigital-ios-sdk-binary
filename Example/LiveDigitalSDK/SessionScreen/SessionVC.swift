import UIKit
import LiveDigitalSDK


final class SessionVC: UIViewController {
	var presenter: SessionPresenter?

	@IBOutlet var localPreviewShadowView: UIView!
	@IBOutlet var localPreviewContainer: UIView!
	@IBOutlet var buttonsContainer: UIView!
	@IBOutlet var localAudioButton: UIButton!
	@IBOutlet var localVideoButton: UIButton!
	@IBOutlet var peersViewsScroller: UIScrollView!
	@IBOutlet var peersViewsContainer: UIStackView!
	@IBOutlet var finishButton: UIButton!
	private var peerViews = [PeerId: PeerView]()

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

		presenter?.viewDidLoad()
	}
}

// MARK: - SessionView implementation

extension SessionVC: SessionView {
	func setupLocalPreview(_ localPreview: UIView) {
		localPreview.translatesAutoresizingMaskIntoConstraints = false
		localPreviewContainer.addSubview(localPreview)
		localPreviewContainer.leftAnchor
			.constraint(equalTo: localPreview.leftAnchor)
			.isActive = true
		localPreviewContainer.rightAnchor
			.constraint(equalTo: localPreview.rightAnchor)
			.isActive = true
		localPreviewContainer.topAnchor
			.constraint(equalTo: localPreview.topAnchor)
			.isActive = true
		localPreviewContainer.bottomAnchor
			.constraint(equalTo: localPreview.bottomAnchor)
			.isActive = true
	}

	func updateAudioButtonState(isOn: Bool) {
		localAudioButton.isSelected = isOn
		localAudioButton.tintColor = isOn ? .systemRed : .systemGray
	}

	func updateVideoButtonState(isOn: Bool) {
		localVideoButton.isSelected = isOn
		localVideoButton.tintColor = isOn ? .systemRed : .systemGray
	}

	func updateCanFinish(_ canFinish: Bool) {
		finishButton.isEnabled = canFinish
	}

	func addPeer(_ peer: Peer) {
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

	func removePeers(_ peerIds: Set<PeerId>) {
		for peerId in peerIds {
			guard let peerView = peerViews[peerId] else {
				return
			}
			peerViews[peerId] = nil
			peerView.removeFromSuperview()
		}
		updateVisiblePeersVideos()
	}

	func updateVideoView(_ videoView: UIView, for peer: Peer, trackLabel: TrackLabel) {
		peerView(for: peer, trackLabel: trackLabel)?.update(videoView: videoView, trackLabel: trackLabel)
	}

	func updateVideo(isActive: Bool, for peer: Peer, trackLabel: TrackLabel) {
		peerView(for: peer, trackLabel: trackLabel)?.update(videoIsActive: isActive)
	}

	func updateAudio(isActive: Bool, for peer: Peer, trackLabel: TrackLabel) {
		peerView(for: peer, trackLabel: trackLabel)?.update(audioIsActive: isActive)
	}

	func updatePeerAppData(_ peerId: PeerId, appData: [String : Any]) {
		guard let peerView = peerViews[peerId] else {
			return
		}
		peerView.update(name: appData["name"] as? String)
	}

	func isVideoTrackVisible(peer: Peer, trackLabel: TrackLabel) -> Bool {
		guard let peerView = peerView(for: peer, trackLabel: trackLabel) else {
			return false
		}
		let visible = isPeerViewVisible(peerView)
		peerView.videoSuspended = !visible
		return visible
	}

	func dismiss() {
		dismiss(animated: true)
	}
}

// MARK: - Private methods

private extension SessionVC {
	func localAudioContextMenu() -> UIContextMenuConfiguration {
		let routes = presenter?.availableAudioRoutes ?? []
		let currentRoute = presenter?.currentAudioRoute

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
							@unknown default:
								title = "\(route.kind) (unsupported)"
						}
						return UIAction(title: title, state: isSelected ? .on : .off,
						handler: { [weak self] _ in
								self?.presenter?.updatePreferred(route: route)
							})
					}

				return UIMenu(title: "Select audio device", children: actions)
			})

		return menuConfig
	}

	func updateVisiblePeersVideos() {
		for (peerId, peerView) in peerViews {
			guard let trackLabel = peerView.trackLabel else {
				continue
			}
			let visible = isPeerViewVisible(peerView)
			if visible == peerView.videoSuspended {
				presenter?.updateVideoTrackVisible(peerId: peerId, trackLabel: trackLabel, isVisible: visible)
				peerView.videoSuspended = !visible
			}
		}
	}

	func isPeerViewVisible(_ view: PeerView) -> Bool {
		let visibleArea = CGRect(origin: peersViewsScroller.contentOffset, size: peersViewsScroller.frame.size)
		let viewFrameInScroll = view.superview?.convert(view.frame, to: peersViewsScroller)
		return viewFrameInScroll?.intersects(visibleArea) ?? false
	}

	func peerView(for peer: Peer, trackLabel: TrackLabel) -> PeerView? {
		if peerViews[peer.id] == nil {
			print("Requesting view for unknown peer \(peer)")
		}

		// TODO: Implement support for several videos from one peer.
		return peerViews[peer.id]
	}

}

// MARK: - UI Actions

private extension SessionVC {
	@IBAction
	func toggleMicrophoneEnabled(_ sender: UIButton) {
		presenter?.updateLocalAudioEnabled(!sender.isSelected)
	}

	@IBAction
	func toggleCameraEnabled(_ sender: UIButton) {
		presenter?.updateLocalVideoEnabled(!sender.isSelected)
	}

	@IBAction
	func toggleCamera(_ sender: UISwipeGestureRecognizer) {
		presenter?.flipCamera()
	}

	@IBAction
	func finishSession(_ sender: UIButton) {
		presenter?.finishSession()
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
