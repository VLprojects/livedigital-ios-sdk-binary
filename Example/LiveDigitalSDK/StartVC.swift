import Foundation
import UIKit
import Combine
import LiveDigitalSDK


@MainActor
final class StartVC: UIViewController {
	private struct Constants {
		static let testRoomAlias = "q3_5V3uwik"

		static let apiEnvironment = MoodhoodAPIEnvironment(
			apiHost: URL(string: "https://moodhood-api.livedigital.space")!,
			clientId: "moodhood-demo",
			clientSecret: "demo12345abcde6789zxcvDemo"
		)
	}

	var callManager: (CallManager & PushPermissionsManager)?

	@IBOutlet private var roomAliasInput: UITextField!
	@IBOutlet private var versionLabel: UILabel!
	@IBOutlet private var requestAPNSPermissionsButton: UIButton!
	@IBOutlet private var copyDeviceTokenButton: UIButton!
	@IBOutlet private var showDeviceTokenQRButton: UIButton!
	private var grayoutView: UIView?

	private let apiClient: MoodhoodAPIClient
	private let qrGenerator: QRGenerator = StockQRGenerator()
	private var tokenQR: UIImage?
	private var cancellables: Set<AnyCancellable> = []

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		self.apiClient = StockMoodhoodAPIClient(environment: Constants.apiEnvironment)
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	required init?(coder: NSCoder) {
		self.apiClient = StockMoodhoodAPIClient(environment: Constants.apiEnvironment)
		super.init(coder: coder)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		roomAliasInput.text = Constants.testRoomAlias
		versionLabel.text = "LiveDigitalSDK version: \(LiveDigital.version())"
		bindAPNSState()
	}

	// MARK: - IBActions

	@IBAction func startByAliasTapped() {
		guard let roomAlias = roomAliasInput.text, !roomAlias.isEmpty else {
			return
		}
		callManager?.startCallManually(to: roomAlias)
	}

	@IBAction func requestAPNSPermissionsTapped() {
		callManager?.requestPermission()
	}

	@IBAction func copyDeviceTokenTapped() {
		UIPasteboard.general.string = callManager?.deviceTokenCurrentValue
	}

	@IBAction func showDeviceTokenQRTapped() {
		guard let token = callManager?.deviceTokenCurrentValue else {
			return
		}
		guard let image = qrGenerator.generate(from: token) else {
			return
		}
		let vc = FullscreenImageVC(image: image)
		present(vc, animated: true)
	}
}

// MARK: - Private methods

private extension StartVC {
	func bindAPNSState() {
		guard let callManager else {
			requestAPNSPermissionsButton.isHidden = true
			copyDeviceTokenButton.isHidden = true
			showDeviceTokenQRButton.isHidden = true
			return
		}

		callManager.addObserver(self)
		applyAPNSPermissionState(callManager.permissionStateCurrentValue)
		callManager.permissionState
			.sink { [weak self] state in
				self?.applyAPNSPermissionState(state)
			}
			.store(in: &cancellables)

		applyDeviceToken(callManager.deviceTokenCurrentValue)
		callManager.deviceToken
			.sink { [weak self] token in
				self?.applyDeviceToken(token)
			}
			.store(in: &cancellables)
	}

	func applyAPNSPermissionState(_ state: PermissionState) {
		switch state {
			case .unknown, .disabled:
				requestAPNSPermissionsButton.isHidden = false
				requestAPNSPermissionsButton.isEnabled = false
			case .undecided:
				requestAPNSPermissionsButton.isHidden = false
				requestAPNSPermissionsButton.isEnabled = true
			case .allowed:
				requestAPNSPermissionsButton.isHidden = true
		}
	}

	func applyDeviceToken(_ token: String?) {
		guard let token else {
			copyDeviceTokenButton.isHidden = true
			showDeviceTokenQRButton.isHidden = true
			tokenQR = nil
			return
		}
		copyDeviceTokenButton.isHidden = false
		tokenQR = qrGenerator.generate(from: token)
		showDeviceTokenQRButton.isHidden = tokenQR == nil
	}

	func openRoom(for call: Call) {
		startActivityIndicator()
		Task {
			do {
				if !apiClient.isAuthorized {
					try await self.apiClient.authorizeAsGuest()
				}
				let room = try await self.apiClient.fetchRoom(roomAlias: call.roomAlias)
				await MainActor.run {
					self.openSession(in: room, call: call)
				}
			} catch {
				callManager?.reportCallEnded(call)
			}
			await MainActor.run {
				self.stopActivityIndicator()
			}
		}
	}

	func openSession(in room: Room, call: Call) {
		let sb = UIStoryboard(name: "Main", bundle: nil)
		guard let sessionVC = sb.instantiateViewController(withIdentifier: "SessionVC") as? SessionVC else {
			return
		}
		sessionVC.call = call
		sessionVC.room = room
		sessionVC.apiClient = apiClient
		sessionVC.callManager = callManager
		sessionVC.modalPresentationStyle = .fullScreen
		present(sessionVC, animated: true, completion: nil)
	}

	func startActivityIndicator() {
		let grayout = UIView()
		grayout.translatesAutoresizingMaskIntoConstraints = false
		grayout.backgroundColor = .black.withAlphaComponent(0.5)
		view.addSubview(grayout)
		grayoutView = grayout
		let spinner = UIActivityIndicatorView(style: .medium)
		spinner.translatesAutoresizingMaskIntoConstraints = false
		spinner.startAnimating()
		grayout.addSubview(spinner)
		NSLayoutConstraint.activate([
			spinner.centerXAnchor.constraint(equalTo: grayout.centerXAnchor),
			spinner.centerYAnchor.constraint(equalTo: grayout.centerYAnchor)
		])
		NSLayoutConstraint.activate([
			grayout.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			grayout.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			grayout.topAnchor.constraint(equalTo: view.topAnchor),
			grayout.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])
	}

	func stopActivityIndicator() {
		grayoutView?.removeFromSuperview()
		grayoutView = nil
	}
}

// MARK: - CallManagerObserver implementation

extension StartVC: @MainActor CallManagerObserver {
	func didReceiveCall(_ call: Call) {
		openRoom(for: call)
	}

	func didInitiateCall(_ call: Call) {
		openRoom(for: call)
	}
}
