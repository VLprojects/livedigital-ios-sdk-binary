import UIKit


final class FullscreenImageVC: UIViewController {
	private let image: UIImage

	init(image: UIImage) {
		self.image = image
		super.init(nibName: nil, bundle: nil)
		modalPresentationStyle = .fullScreen
	}

	required init?(coder: NSCoder) {
		fatalError("Not implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .black

		let imageView = UIImageView(image: image)
		imageView.contentMode = .scaleAspectFit
		imageView.frame = view.bounds
		imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		imageView.layer.magnificationFilter = .nearest
		imageView.layer.minificationFilter = .nearest
		view.addSubview(imageView)

		let tap = UITapGestureRecognizer(target: self, action: #selector(close))
		view.addGestureRecognizer(tap)
	}

	@objc private func close() {
		dismiss(animated: true)
	}
}
