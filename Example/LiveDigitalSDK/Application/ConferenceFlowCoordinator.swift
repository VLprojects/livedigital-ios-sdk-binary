import Foundation
import UIKit
import SwiftUI


@MainActor
final class ConferenceFlowCoordinator {
	private let apiClient: MoodhoodAPIClient
	private let window: UIWindow
	private weak var spinner: UIView?
	private var currentCallScreen: UIViewController?

	init(window: UIWindow) {
		let apiEnvironment = MoodhoodAPIEnvironment(
			apiHost: URL(string: AppConfig.moodhoodAPIBaseURL)!,
			clientId: AppConfig.moodhoodAPIClientId,
			clientSecret: AppConfig.moodhoodAPIClientSecret
		)
		self.apiClient = StockMoodhoodAPIClient(environment: apiEnvironment)
		self.window = window
	}

	func joinRoom(alias: String) {
		dismissCallScreen()
		startActivityIndicator()
		Task {
			do {
				if !apiClient.isAuthorized {
					try await self.apiClient.authorizeAsGuest()
				}
				let room = try await self.apiClient.fetchRoom(roomAlias: alias)
				self.openSession(in: room)
			} catch {
				print("Failed to open room: \(error)")
			}
			self.stopActivityIndicator()
		}
	}
}

// MARK: - ConferenceScreenCoordinator implementation

extension ConferenceFlowCoordinator: ConferenceScreenCoordinator {
	func dismissCallScreen() {
		currentCallScreen?.dismiss(animated: true)
		currentCallScreen = nil
	}
}

// MARK: - Private methods

private extension ConferenceFlowCoordinator {
	func openSession(in room: Room) {
		let vm = ConferenceSessionVM(apiClient: apiClient, room: room)
		vm.coordinator = self
		let view = ConferenceSessionView(vm: vm)
		let vc = UIHostingController(rootView: view)
		vc.modalPresentationStyle = UIModalPresentationStyle.fullScreen
		currentCallScreen = vc
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
