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
				guard let data = UserDefaults.standard.value(forKey: key.rawValue) as? Data,
					let decodedData = try? JSONDecoder().decode(T.self, from: data) else {
						return defaultValue
				}
				return decodedData
			}
			set {
				if let encoded = try? JSONEncoder().encode(newValue) {
					UserDefaults.standard.set(encoded, forKey: key.rawValue)
				}
				UserDefaults.standard.synchronize()
			}
		}
	}
}
