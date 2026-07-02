import Foundation


struct Defaults {
	enum Keys: String {
		case deviceId
		case localPhoneNumber
		case outgoingPhoneNumber
		case isSignedIn
		case appWorkflow
	}

	@StoredValue(key: .deviceId)
	static var deviceId: String?

	@StoredValue(key: .localPhoneNumber)
	static var localPhoneNumber: String?

	@StoredValue(key: .outgoingPhoneNumber)
	static var outgoingPhoneNumber: String?

	@StoredValue(key: .isSignedIn)
	static var isSignedIn: Bool?

	@StoredValue(key: .appWorkflow)
	static var appWorkflow: AppWorkflow?
}
