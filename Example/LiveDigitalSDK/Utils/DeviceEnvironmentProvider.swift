import Foundation
import UIKit


enum DeviceEnvironmentProvider {
	static var environment: DeviceEnvironment {
		DeviceEnvironment(
			apnsEnvironment: Self.apnsEnvironment,
			deviceId: Self.deviceId,
			deviceName: "\(Self.deviceModel) @ \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
			timeZoneCode: TimeZone.current.identifier,
			languageCode: Locale.current.languageCode
		)
	}
}

// MARK: - Private methods

private extension DeviceEnvironmentProvider {
	static var deviceModel: String {
		var systemInfo = utsname()
		uname(&systemInfo)
		let machineMirror = Mirror(reflecting: systemInfo.machine)
		let identifier = machineMirror.children.reduce("") { identifier, element in
			guard let value = element.value as? Int8, value != 0 else { return identifier }
			return identifier + String(UnicodeScalar(UInt8(value)))
		}
		return identifier
	}

	static var deviceId: String {
		if let storedValue = Defaults.deviceId {
			return storedValue.lowercased()
		} else {
			let newValue = UUID().uuidString.lowercased()
			Defaults.deviceId = newValue
			return newValue
		}
	}

	static var apnsEnvironment: APNSEnvironment {
		guard let provisionURL = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
			let entitlements = Self.readProvisioningEntitlements(at: provisionURL),
			let apsEnvironment = entitlements["aps-environment"] as? String else {
			// Default fallback for App Store builds
			return .production
		}
		return apsEnvironment == "development" ? .sandbox : .production
	}

	static func readProvisioningEntitlements(at url: URL) -> [String: Any]? {
		guard let data = try? Data(contentsOf: url),
			let plistRange = data.range(of: Data("<?xml".utf8)),
			let plistEnd = data.range(of: Data("</plist>".utf8), in: plistRange.lowerBound..<data.endIndex) else {
			return nil
		}
		let plistData = data.subdata(in: plistRange.lowerBound..<plistEnd.upperBound)
		guard let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
			return nil
		}
		return plist["Entitlements"] as? [String: Any]
	}
}
