import Foundation
import UserNotifications


final class StockCRSAPIClient {
	private enum Endpoints {
		static func registerDeviceToken(deviceId: String) -> String {
			"/v1/devices/\(deviceId)"
		}
		static func unregisterDevice(deviceId: String) -> String {
			"/v1/devices/\(deviceId)"
		}
	}

	private let apiClient: APIClient
	private let apiEnvironment: CRSAPIEnvironment
	private let deviceEnvironment: DeviceEnvironment

	init(apiEnvironment: CRSAPIEnvironment, deviceEnvironment: DeviceEnvironment) {
		self.apiClient = StockAPIClient(baseURL: apiEnvironment.apiHost)
		self.apiEnvironment = apiEnvironment
		self.deviceEnvironment = deviceEnvironment
	}
}

// MARK: - CRSAPIClient implementation

extension StockCRSAPIClient: CRSAPIClient {
	func registerDeviceToken(
		phoneNumber: String,
		pushToken: String
	) async throws(APIClientError) -> RegisteredDevice {
		return try await apiClient.put(
			endpoint: Endpoints.registerDeviceToken(deviceId: deviceEnvironment.deviceId),
			headers: [
				"X-API-Key": apiEnvironment.apiKey
			],
			parameters: [
				"phoneNumber": phoneNumber,
				"pushToken": pushToken,
				"pushEnvironment": environmentString(deviceEnvironment.apnsEnvironment),
				"pushPlatform": "apns_voip",
				"deviceName": deviceEnvironment.deviceName,
				"timezone": deviceEnvironment.timeZoneCode,
				"locale": deviceEnvironment.languageCode as Any
			]
		)
	}

	func unregisterDevice() async throws(APIClientError) {
		var _: EmptyResult = try await apiClient.delete(
			endpoint: Endpoints.unregisterDevice(deviceId: deviceEnvironment.deviceId),
			headers: [
				"X-API-Key": apiEnvironment.apiKey
			]
		)
	}

	func list(
		for phoneNumber: String
	) async throws(APIClientError) -> [RegisteredDevice] {
		throw .failedToComposeRequest
	}

	func fetch() async throws(APIClientError) -> RegisteredDevice {
		throw .failedToComposeRequest
	}
}

// MARK: - Private methods

private extension StockCRSAPIClient {
	func environmentString(_ environment: APNSEnvironment) -> String {
		return switch environment {
			case .sandbox: "sandbox"
			case .production: "production"
		}
	}
}
