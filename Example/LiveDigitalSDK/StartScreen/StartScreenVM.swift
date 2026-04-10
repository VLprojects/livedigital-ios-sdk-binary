import Foundation
import SwiftUI


@MainActor
final class StartScreenVM: ObservableObject {
	@Published var apnsPermissionGranted = false
	@Published var microphonePermissionGranted = false
	@Published var cameraPermissionGranted = false

	private let apnsPermissionManager: PushPermissionsManager
	private let microphonePermissionManager: CaptureDevicePermissionsManager
	private let cameraPermissionManager: CaptureDevicePermissionsManager

	init(
		apnsPermissionManager: PushPermissionsManager,
		microphonePermissionManager: CaptureDevicePermissionsManager,
		cameraPermissionManager: CaptureDevicePermissionsManager
	) {
		self.apnsPermissionManager = apnsPermissionManager
		self.microphonePermissionManager = microphonePermissionManager
		self.cameraPermissionManager = cameraPermissionManager

		bindPermissionsStates()
	}
}

// MARK: - Internal methods

internal extension StartScreenVM {
	func requestApnsPermission() {
		apnsPermissionManager.requestPermission()
	}

	func requestCameraPermission() {
		cameraPermissionManager.requestPermission()
	}

	func requestMicrophonePermission() {
		microphonePermissionManager.requestPermission()
	}
}


// MARK: - Private methods

private extension StartScreenVM {
	func bindPermissionsStates() {
		apnsPermissionManager.permissionState
			.map { $0 == .allowed }
			.receive(on: DispatchQueue.main)
			.assign(to: &$apnsPermissionGranted)

		cameraPermissionManager.permissionState
			.map { $0 == .allowed }
			.receive(on: DispatchQueue.main)
			.assign(to: &$cameraPermissionGranted)

		microphonePermissionManager.permissionState
			.map { $0 == .allowed }
			.receive(on: DispatchQueue.main)
			.assign(to: &$microphonePermissionGranted)
	}
}
