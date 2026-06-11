import Foundation
import Combine


protocol CaptureDevicePermissionsManager {
	var permissionState: AnyPublisher<PermissionState, Never> { get }
	var permissionStateCurrentValue: PermissionState { get }

	func requestPermission()
}
