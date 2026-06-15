import Foundation


struct Defaults {
	enum Keys: String {
		case deviceId
		case phoneNumber
	}

	@StoredValue(key: .deviceId)
	static var deviceId: String?

	@StoredValue(key: .phoneNumber)
	static var phoneNumber: String?
}
