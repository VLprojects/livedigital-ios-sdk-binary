import Foundation
import UIKit
import SwiftUI


@MainActor
final class CallCoordinator {
	private enum Constants {
		static let apiEnvironment = MoodhoodAPIEnvironment(
			apiHost: URL(string: "https://moodhood-api.livedigital.space")!,
			clientId: "moodhood-demo",
			clientSecret: "demo12345abcde6789zxcvDemo"
		)
	}

	private let callManager: CallManager
	private let apiClient: MoodhoodAPIClient
	private let window: UIWindow
	private weak var spinner: UIView?
	private var callScreens = [UUID: UIViewController]()
	private var redialRooms = [String: Room]()

	init(callManager: CallManager, window: UIWindow) {
		self.callManager = callManager
		self.apiClient = StockMoodhoodAPIClient(environment: Constants.apiEnvironment)
		self.window = window

		callManager.addObserver(self)
	}
}

// MARK: - CallManagerObserver implementation

extension CallCoordinator: @MainActor CallManagerObserver {
	func didReceiveCall(_ call: Call) {
		dismissCurrentCalls()
		openRoom(for: call)
	}

	func didEndCall(_ call: Call) {
		if UIApplication.shared.applicationState != .active {
			// Avoid presenting "redial" screen if user has ended the call via system caller UI
			callScreens.removeValue(forKey: call.id)?.dismiss(animated: false)
		}
	}

	func didInitiateCall(_ call: Call) {
		dismissCurrentCalls()
		openRoom(for: call)
	}
}

// MARK: - CallScreenCoordinator implementation

extension CallCoordinator: CallScreenCoordinator {
	func dismissCallScreen(call: Call) {
		callScreens.removeValue(forKey: call.id)?.dismiss(animated: true)
	}

	func redial(to room: Room) {
		dismissCurrentCalls()

		// We must initiate all calls via callManager because of CallKit architecture.
		// Outgoing calls are started indirectly via CallKit callback method and then via `didInitiateCall` method.
		// So we can not pass Room object to the `openRoom` method via this call stack which includes CallKit.
		// To avoid refetching Room, we save it to a temporary storage while waiting for `didInitiateCall` call.
		redialRooms[room.alias] = room
		callManager.startCallManually(to: room.alias)
	}
}

// MARK: - Private methods

private extension CallCoordinator {
	func dismissCurrentCalls() {
		for (callId, callScreen) in callScreens {
			callManager.endCall(callId)
			callScreen.dismiss(animated: true)
		}
		callScreens.removeAll()
	}

	func openRoom(for call: Call) {
		if let room = redialRooms[call.roomAlias] {
			redialRooms.removeValue(forKey: call.roomAlias)
			openSession(in: room, call: call)
		} else {
			startActivityIndicator()
			Task {
				do {
					if !apiClient.isAuthorized {
						try await self.apiClient.authorizeAsGuest()
					}
					let room = try await self.apiClient.fetchRoom(roomAlias: call.roomAlias)
					self.openSession(in: room, call: call)
				} catch {
					callManager.reportCallEnded(call)
				}
				self.stopActivityIndicator()
			}
		}
	}

	func openSession(in room: Room, call: Call) {
		let vm = AudioCallVM(callManager: callManager, apiClient: apiClient, room: room, call: call)
		vm.coordinator = self
		let view = AudioCallView(vm: vm)
		let vc = UIHostingController(rootView: view)
		vc.modalPresentationStyle = UIModalPresentationStyle.fullScreen
		callScreens[call.id] = vc
		window.rootViewController?.present(vc, animated: true)
	}

	func startActivityIndicator() {
		guard let rootVC = window.rootViewController else {
			return
		}

		let spinner = UIActivityIndicatorView(style: .large)
		spinner.translatesAutoresizingMaskIntoConstraints = false
		spinner.color = AssetColor.contrast.uiColor
		spinner.startAnimating()
		rootVC.view.addSubview(spinner)
		spinner.centerXAnchor.constraint(equalTo: rootVC.view.centerXAnchor).isActive = true
		spinner.centerYAnchor.constraint(equalTo: rootVC.view.centerYAnchor).isActive = true
		self.spinner = spinner
	}

	func stopActivityIndicator() {
		guard let spinner else {
			return
		}
		spinner.removeFromSuperview()
	}
}
