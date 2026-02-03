import UIKit
import Intents


final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	private var callManager = StockCallManager()

	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let window else {
			return
		}

		window.backgroundColor = .systemBackground
		if let startVC = window.rootViewController as? StartVC {
			startVC.callManager = callManager
		}

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
