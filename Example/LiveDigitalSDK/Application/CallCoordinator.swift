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
				await MainActor.run {
					self.openSession(in: room, call: call)
				}
			} catch {
				callManager.reportCallEnded(call)
			}
			await MainActor.run {
				self.stopActivityIndicator()
			}
		}
	}

	func openSession(in room: Room, call: Call) {
		let vm = AudioCallVM(callManager: callManager, apiClient: apiClient)
		let view = AudioCallView(vm: vm)
		let vc = UIHostingController(rootView: view)
		vc.modalPresentationStyle = UIModalPresentationStyle.fullScreen
		window.rootViewController?.present(vc, animated: true)
	}

	func startActivityIndicator() {
	}

	func stopActivityIndicator() {
	}
}
