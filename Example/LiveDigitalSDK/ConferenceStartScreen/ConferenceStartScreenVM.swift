import Foundation
import SwiftUI
import Combine
import LiveDigitalSDK


@MainActor
final class ConferenceStartScreenVM: ObservableObject {
	@Published var microphonePermissionGranted = false
	@Published var cameraPermissionGranted = false
	@Published var canJoinRoom = false
	@Published var roomAlias = "q3_5V3uwik"

	weak var coordinator: ConferenceFlowCoordinator?

	let notificationsVM = NotificationsVM()

	private let microphonePermissionManager: CaptureDevicePermissionsManager
	private let cameraPermissionManager: CaptureDevicePermissionsManager
	private var cancellables = Set<AnyCancellable>()

	init(
		microphonePermissionManager: CaptureDevicePermissionsManager,
		cameraPermissionManager: CaptureDevicePermissionsManager
	) {
		self.microphonePermissionManager = microphonePermissionManager
		self.cameraPermissionManager = cameraPermissionManager

		bindPermissionsStates()
		bindOutgoingCallState()
		notificationsVM.show("LiveDigitalSDK version: \(LiveDigital.version())")
	}
}

// MARK: - Internal methods

internal extension ConferenceStartScreenVM {
	func requestCameraPermission() {
		cameraPermissionManager.requestPermission()
	}

	func requestMicrophonePermission() {
		microphonePermissionManager.requestPermission()
	}

	func joinRoom() {
		coordinator?.joinRoom(alias: roomAlias)
	}
}

// MARK: - Private methods

private extension ConferenceStartScreenVM {
	func bindPermissionsStates() {
		cameraPermissionManager.permissionState
			.map { $0 == .allowed }
			.receive(on: DispatchQueue.main)
			.assign(to: &$cameraPermissionGranted)

		microphonePermissionManager.permissionState
			.map { $0 == .allowed }
			.receive(on: DispatchQueue.main)
			.assign(to: &$microphonePermissionGranted)
	}

	func bindOutgoingCallState() {
		$roomAlias
			.map { !$0.isEmpty }
			.receive(on: DispatchQueue.main)
			.assign(to: &$canJoinRoom)
	}
}
