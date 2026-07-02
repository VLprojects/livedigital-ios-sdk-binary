import Foundation


final class FakeAccountManager {
	@Published private(set) var isSignedIn: Bool

	private let callManager: CallManager
	private let crsClient: CRSAPIClient
	private let apnsTokenProvider: APNSTokenProvider

	init(callManager: CallManager, apnsTokenProvider: APNSTokenProvider) {
		self.callManager = callManager
		self.apnsTokenProvider = apnsTokenProvider
		self.isSignedIn = Defaults.isSignedIn ?? false

		guard let baseURL = URL(string: AppConfig.crsAPIBaseURL) else {
			fatalError("Failed to parse URL from value \(AppConfig.crsAPIBaseURL)")
		}
		let crsEnvironment = CRSAPIEnvironment(apiHost: baseURL, apiKey: AppConfig.crsAPIKey)
		self.crsClient = StockCRSAPIClient(
			apiEnvironment: crsEnvironment,
			deviceEnvironment: DeviceEnvironmentProvider.environment
		)
	}
}

// MARK: - AccountManager implementation

extension FakeAccountManager: AccountManager {
	var isSignedInPublisher: Published<Bool>.Publisher { $isSignedIn }

	func signIn(phone: String) async throws -> RegisteredDevice {
		Defaults.phoneNumber = phone
		callManager.localPhone = phone

		guard let pushToken = apnsTokenProvider.deviceTokenCurrentValue else {
			throw APIClientError.failedToComposeRequest
		}

		let result = try await crsClient.registerDeviceToken(
			phoneNumber: phone,
			pushToken: pushToken
		)

		isSignedIn = true
		Defaults.isSignedIn = true

		return result
	}

	func signOut() async throws {
		Defaults.isSignedIn = false
		isSignedIn = false
		callManager.localPhone = nil
		try await crsClient.unregisterDevice()
	}
}
