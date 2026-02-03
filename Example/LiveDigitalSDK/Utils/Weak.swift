import Foundation


struct Weak<T> {
	private weak var mValue: AnyObject?

	var value: T? {
		return mValue as? T
	}

	init(value: T) {
		// A workaround to check for value-type objects.
		// If `value` is not a reference-type, crash will occur.
		_ = Unmanaged.passUnretained(value as AnyObject)

		self.mValue = value as AnyObject
	}
}

// MARK: - Equatable implementation

extension Weak: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		if let lValue = lhs.mValue, let rValue = rhs.mValue {
			return lValue === rValue
		} else {
			return false
		}
	}
}

// MARK: - Hashable implementation

extension Weak: Hashable {
	func hash(into hasher: inout Hasher) {
		if let value = mValue {
			hasher.combine(ObjectIdentifier(value).hashValue)
		} else {
			hasher.combine(0)
		}
	}
}
