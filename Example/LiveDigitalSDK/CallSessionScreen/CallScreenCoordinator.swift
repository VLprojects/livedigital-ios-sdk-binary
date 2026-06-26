import Foundation


@MainActor
protocol CallScreenCoordinator: AnyObject {
	func dismissCallScreen(call: Call)
	func redial(after call: Call)
}
