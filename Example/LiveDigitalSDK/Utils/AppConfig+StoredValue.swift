import Foundation


extension AppConfig {
	@propertyWrapper
	struct StoredValue {
		private let key: AppConfig.Keys
		private let defaultValue: String?

		init(key: AppConfig.Keys, defaultValue: String? = nil) {
			self.key = key
			self.defaultValue = defaultValue
		}

		var wrappedValue: String {
			get {
				if let value = ProcessInfo.processInfo.environment[key.rawValue], !value.isEmpty {
					return value
				} else if let value = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String, !value.isEmpty {
					return value
				} else if let value = defaultValue {
					return value
				} else {
					fatalError("\(key.rawValue) must be defined in Info.plist or passed as build-time or runtime environment variable!")
				}
			}
		}
	}
}
