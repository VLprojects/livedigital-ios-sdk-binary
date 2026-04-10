import UIKit
import Intents
import SwiftUI


final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	private let callManager = StockCallManager()
	var startVC: UIViewController?

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
			apnsPermissionManager: callManager,
			microphonePermissionManager: StockCaptureDevicePermissionsManager(deviceType: .microphone),
			cameraPermissionManager: StockCaptureDevicePermissionsManager(deviceType: .camera)
		)
		let startView = StartScreenView(vm: startVM)
		let startVC = UIHostingController(rootView: startView)
		window.rootViewController = startVC
		self.startVC = startVC

		window.makeKeyAndVisible()

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
