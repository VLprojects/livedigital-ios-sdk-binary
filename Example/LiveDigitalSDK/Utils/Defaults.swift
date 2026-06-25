import Foundation


struct Defaults {
	enum Keys: String {
		case deviceId
		case phoneNumber
		case isSignedIn
		case appWorkflow
	}

	@StoredValue(key: .deviceId)
	static var deviceId: String?

	@StoredValue(key: .phoneNumber)
	static var phoneNumber: String?

	@StoredValue(key: .isSignedIn)
	static var isSignedIn: Bool?

	@StoredValue(key: .appWorkflow)
	static var appWorkflow: AppWorkflow?
}
