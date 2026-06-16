import Foundation
import Combine


/// This is a simplified example of CRS (Call Registration Service) integration.
///
/// In production, the CRS API should NOT be called directly from a mobile app.
/// Instead, the app should communicate with its own backend, which handles
/// authentication and calls the CRS API on the app's behalf.
/// The backend effectively acts as an authenticated proxy between the
/// mobile client and the CRS service.
protocol AccountManager {
	var isSignedIn: Bool { get }
	var isSignedInPublisher: Published<Bool>.Publisher { get }

	func signIn(phone: String) async throws -> RegisteredDevice
	func signOut() async throws
}
