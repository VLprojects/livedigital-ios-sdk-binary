import Foundation
import Combine
import AVFoundation


final class StockCaptureDevicePermissionsManager {
	let deviceType: CaptureDeviceType

	private let permissionStateSubject = CurrentValueSubject<PermissionState, Never>(.unknown)

	init(deviceType: CaptureDeviceType) {
		self.deviceType = deviceType
		refreshAuthorizationStatus()
	}
}

// MARK: - CaptureDevicePermissionsManager implementation

extension StockCaptureDevicePermissionsManager: CaptureDevicePermissionsManager {
	var permissionState: AnyPublisher<PermissionState, Never> {
		permissionStateSubject.eraseToAnyPublisher()
	}

	var permissionStateCurrentValue: PermissionState {
		permissionStateSubject.value
	}

	func requestPermission() {
		AVCaptureDevice.requestAccess(for: deviceType.avMediaType) { [weak self] _ in
			self?.refreshAuthorizationStatus()
		}
	}
}

// MARK: - Private methods

private extension StockCaptureDevicePermissionsManager {
	func refreshAuthorizationStatus() {
		let avStatus = AVCaptureDevice.authorizationStatus(for: deviceType.avMediaType)
		let permissionState: PermissionState = switch avStatus {
			case .notDetermined: .undecided
			case .restricted: .disabled
			case .denied: .disabled
			case .authorized: .allowed
			@unknown default: .unknown
		}
		permissionStateSubject.send(permissionState)
	}
}

// MARK: - Private methods

private extension CaptureDeviceType {
	var avMediaType: AVMediaType {
		switch self {
			case .camera: return .video
			case .microphone: return .audio
		}
	}
}
