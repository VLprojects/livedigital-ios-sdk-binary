import Foundation


enum AppConfig {
	enum Keys: String {
		case crsAPIBaseURL = "CRS_API_BASE_URL"
		case crsAPIKey = "CRS_API_KEY"
		case callSignalingBaseURL = "CALL_SIGNALING_BASE_URL"
	}

	@StoredValue(key: .crsAPIBaseURL)
	static var crsAPIBaseURL: String

	@StoredValue(key: .crsAPIKey)
	static var crsAPIKey: String

	@StoredValue(key: .callSignalingBaseURL)
	static var callSignalingBaseURL: String
}
