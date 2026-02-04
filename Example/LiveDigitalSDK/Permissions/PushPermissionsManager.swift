import Foundation
import Combine


protocol PushPermissionsManager {
	var permissionState: AnyPublisher<PermissionState, Never> { get }
	var permissionStateCurrentValue: PermissionState { get }

	func requestPermission()
}
