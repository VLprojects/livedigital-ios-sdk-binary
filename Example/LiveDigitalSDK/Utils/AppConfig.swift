import Foundation


enum AppConfig {
	enum Keys: String {
		case moodhoodAPIBaseURL = "MOODHOOD_API_BASE_URL"
		case moodhoodAPIClientId = "MOODHOOD_API_CLIENT_ID"
		case moodhoodAPIClientSecret = "MOODHOOD_API_CLIENT_SECRET"
		case crsAPIBaseURL = "CRS_API_BASE_URL"
		case crsAPIKey = "CRS_API_KEY"
		case callSignalingBaseURL = "CALL_SIGNALING_BASE_URL"
		case signalingTokenSecret = "SIGNALING_TOKEN_SECRET"
	}

	@StoredValue(key: .moodhoodAPIBaseURL)
	static var moodhoodAPIBaseURL: String

	@StoredValue(key: .moodhoodAPIClientId)
	static var moodhoodAPIClientId: String
	
	@StoredValue(key: .moodhoodAPIClientSecret)
	static var moodhoodAPIClientSecret: String

	@StoredValue(key: .crsAPIBaseURL)
	static var crsAPIBaseURL: String

	@StoredValue(key: .crsAPIKey)
	static var crsAPIKey: String

	@StoredValue(key: .callSignalingBaseURL)
	static var callSignalingBaseURL: String

	@StoredValue(key: .signalingTokenSecret)
	static var signalingTokenSecret: String
}
