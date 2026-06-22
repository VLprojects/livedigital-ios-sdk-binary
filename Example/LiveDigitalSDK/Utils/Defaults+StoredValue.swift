import Foundation


extension Defaults {
	@propertyWrapper
	struct StoredValue<T: Codable> {
		private let key: Defaults.Keys
		private let defaultValue: T?

		init(key: Defaults.Keys, defaultValue: T? = nil) {
			self.key = key
			self.defaultValue = defaultValue
		}

		var wrappedValue: T? {
			get {
				let storedValue = UserDefaults.standard.object(forKey: key.rawValue) as? T
				return storedValue ?? defaultValue
			}
			set {
				UserDefaults.standard.set(newValue, forKey: key.rawValue)
				UserDefaults.standard.synchronize()
			}
		}
	}
}
