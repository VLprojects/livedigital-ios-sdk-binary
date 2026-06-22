import Foundation


struct RegisteredDevice: Codable {
	let deviceId: String
	let phoneNumber: String
	let pushPlatform: String
	let pushEnvironment: String
	let isTokenValid: Bool
	let invalidationReason: TokenInvalidationReason?
	let deviceName: String?
	let timezone: String?
	let locale: String?
	let createdAt: Date
	let updatedAt: Date
}
