import UIKit
import LiveDigitalSDK


final class PeerView: UIView {
	internal var videoSuspended: Bool = false
	internal private(set) var trackLabel: TrackLabel?

	@IBOutlet private var noVideoLabel: UILabel!
	@IBOutlet private var nameLabel: UILabel!
	@IBOutlet private var videoContainer: UIView!
	@IBOutlet private var iconsContainer: UIView!
	@IBOutlet private var audioIcon: UIImageView!
	@IBOutlet private var videoIcon: UIImageView!

	private var videoView: UIView?

	override func awakeFromNib() {
		super.awakeFromNib()

		nameLabel.text = nil
		backgroundColor = .systemBackground
		videoContainer.backgroundColor = .secondarySystemBackground

		iconsContainer.layer.masksToBounds = true
		iconsContainer.layer.cornerRadius = 20
		videoContainer.layer.masksToBounds = true
		videoContainer.layer.cornerRadius = 20
	}

	func update(name: String?) {
		nameLabel.text = name
	}

	func update(videoView: UIView?, trackLabel: TrackLabel) {
		guard videoView?.superview !== videoContainer else {
			return
		}

		for subview in videoContainer.subviews {
			subview.removeFromSuperview()
		}

		if let videoView = videoView {
			videoView.translatesAutoresizingMaskIntoConstraints = false
			videoContainer.addSubview(videoView)
			videoContainer.addSubview(videoView)
			videoView.heightAnchor.constraint(equalTo: videoContainer.heightAnchor).isActive = true
			videoView.widthAnchor.constraint(equalTo: videoContainer.widthAnchor).isActive = true
		}

		self.videoView = videoView
		self.trackLabel = trackLabel
	}

	func update(audioIsActive: Bool) {
		audioIcon.image = audioIsActive ?
			UIImage(systemName: "speaker") :
			UIImage(systemName: "speaker.slash")

		audioIcon.tintColor = audioIsActive ?
			UIColor.systemGreen :
			UIColor.systemGray
	}

	func update(videoIsActive: Bool) {
		videoIcon.image = videoIsActive ?
			UIImage(systemName: "video") :
			UIImage(systemName: "video.slash")

		videoIcon.tintColor = videoIsActive ?
			UIColor.systemGreen :
			UIColor.systemGray

		videoView?.isHidden = !videoIsActive
		noVideoLabel.isHidden = videoIsActive
	}
}
