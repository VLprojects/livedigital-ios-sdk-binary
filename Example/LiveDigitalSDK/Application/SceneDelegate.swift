import UIKit
import Intents
import SwiftUI


final class SceneDelegate: UIResponder {
	var window: UIWindow?

	private let callManager: CallManager
	private let pushPermissionsManager: PushPermissionsManager

	private var callCoordinator: CallCoordinator?
	private var startVC: UIViewController?

	override init() {
		let callManager = StockCallManager()
		self.callManager = callManager
		self.pushPermissionsManager = callManager
		super.init()
	}
}

// MARK: - UIWindowSceneDelegate implementation

extension SceneDelegate: UIWindowSceneDelegate {
	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let windowScene = scene as? UIWindowScene else {
			return
		}
		let window = UIWindow(windowScene: windowScene)
		window.backgroundColor = .systemBackground
		self.window = window

		let startVM = StartScreenVM(
			callManager: callManager,
			apnsPermissionManager: pushPermissionsManager,
			microphonePermissionManager: StockCaptureDevicePermissionsManager(deviceType: .microphone),
			cameraPermissionManager: StockCaptureDevicePermissionsManager(deviceType: .camera)
		)
		let startView = StartScreenView(vm: startVM)
		let startVC = UIHostingController(rootView: startView)
		window.rootViewController = startVC
		self.startVC = startVC

		window.makeKeyAndVisible()

		self.callCoordinator = CallCoordinator(
			callManager: callManager,
			window: window
		)

		if let intent = connectionOptions.userActivities.first?.interaction?.intent {
			callManager.startCallFromIntent(intent)
		}
	}

	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		if let intent = userActivity.interaction?.intent {
			callManager.startCallFromIntent(intent)
		}
	}
}
