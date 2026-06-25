import UIKit
import Intents
import SwiftUI


final class SceneDelegate: UIResponder {
	var window: UIWindow?

	private let callManager: CallManager
	private let apnsTokenProvider: APNSTokenProvider
	private let pushPermissionsManager: PushPermissionsManager
	private var callCoordinator: CallCoordinator?

	override init() {
		let callManager = StockCallManager()
		self.callManager = callManager
		self.apnsTokenProvider = callManager
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
		startSelectedFlow()
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

// MARK: - Private methods

private extension SceneDelegate {
	func startSelectedFlow() {
		switch Defaults.appWorkflow {
			case .none: startFlowSelection()
			case .call: startCallFlow()
			case .conference: startConferenceFlow()
		}
	}

	func startFlowSelection() {
		guard let window else {
			print("Failed to start flow selection: no window")
			return
		}

		let selectionView = FlowSelectionView { [weak self] flow in
			Defaults.appWorkflow = flow
			self?.startSelectedFlow()
		}
		let startVC = UIHostingController(rootView: selectionView)
		window.rootViewController = startVC
	}

	func startCallFlow() {
		guard let window else {
			print("Failed to start call flow: no window")
			return
		}

		let startVM = CallStartScreenVM(
			callManager: callManager,
			apnsTokenProvider: apnsTokenProvider,
			apnsPermissionManager: pushPermissionsManager,
			microphonePermissionManager: StockCaptureDevicePermissionsManager(deviceType: .microphone),
			cameraPermissionManager: StockCaptureDevicePermissionsManager(deviceType: .camera)
		)
		let startView = CallStartScreenView(vm: startVM)
		let startVC = UIHostingController(rootView: startView)
		window.rootViewController = startVC
		self.callCoordinator = CallCoordinator(
			callManager: callManager,
			window: window
		)
	}

	func startConferenceFlow() {
	}
}
