import Foundation


protocol CRSAPIClient {
	func registerDeviceToken(
		phoneNumber: String,
		pushToken: String
	) async throws(APIClientError) -> RegisteredDevice

	func unregisterDevice() async throws(APIClientError)

	func list(
		for phoneNumber: String
	) async throws(APIClientError) -> [RegisteredDevice]

	func fetch() async throws(APIClientError) -> RegisteredDevice
}
