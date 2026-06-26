import Foundation
import UIKit
import SwiftUI


@MainActor
final class CallFlowCoordinator {
	private let callManager: CallManager
	private let window: UIWindow
	private weak var spinner: UIView?
	private var callScreens = [UUID: UIViewController]()

	init(callManager: CallManager, window: UIWindow) {
		self.callManager = callManager
		self.window = window

		callManager.addObserver(self)
	}
}

// MARK: - CallManagerObserver implementation

extension CallFlowCoordinator: @MainActor CallManagerObserver {
	func didReceiveCall(_ call: Call) {
		dismissCurrentCalls()
		openCall(call)
	}

	func didEndCall(_ call: Call) {
		if UIApplication.shared.applicationState != .active {
			// Avoid presenting "redial" screen if user has ended the call via system caller UI
			callScreens.removeValue(forKey: call.id)?.dismiss(animated: false)
		}
	}

	func didInitiateCall(_ call: Call) {
		dismissCurrentCalls()
		openCall(call)
	}
}

// MARK: - CallScreenCoordinator implementation

extension CallFlowCoordinator: CallScreenCoordinator {
	func dismissCallScreen(call: Call) {
		callScreens.removeValue(forKey: call.id)?.dismiss(animated: true)
	}

	func redial(after call: Call) {
		dismissCurrentCalls()

		// We must initiate all calls via callManager because of CallKit architecture.
		// Outgoing calls are started indirectly via CallKit callback method and then via `didInitiateCall` method.

		// TODO: Implement me!
		// callManager.startCallManually(to: )
	}
}

// MARK: - Private methods

private extension CallFlowCoordinator {
	func dismissCurrentCalls() {
		for (callId, callScreen) in callScreens {
			callManager.endCall(callId)
			callScreen.dismiss(animated: true)
		}
		callScreens.removeAll()
	}

	func openCall(_ call: Call) {
		let vm = AudioCallVM(callManager: callManager, call: call)
		vm.coordinator = self
		let view = AudioCallView(vm: vm)
		let vc = UIHostingController(rootView: view)
		vc.modalPresentationStyle = UIModalPresentationStyle.fullScreen
		callScreens[call.id] = vc
		window.rootViewController?.present(vc, animated: true)
	}
}
