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
		openRoom(for: call)
	}

	func didInitiateCall(_ call: Call) {
		openRoom(for: call)
	}

	func didEndCall(_ call: Call) {
		callScreens.removeValue(forKey: call.id)?.dismiss(animated: true)
	}
}

// MARK: - Private methods

private extension CallCoordinator {
	func openRoom(for call: Call) {
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

	func openSession(in room: Room, call: Call) {
		let vm = AudioCallVM(callManager: callManager, apiClient: apiClient, room: room, call: call)
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
