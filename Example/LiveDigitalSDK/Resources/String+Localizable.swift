import Foundation


struct L10n {
	let key: String
	let table: String?

	init(_ key: String, table: String? = nil) {
		self.key = key
		self.table = table
	}
}

extension L10n {
	static let apnsPermissionTitle = L10n("apnsPermissionTitle")
	static let apnsTokenCopiedNotification = L10n("apnsTokenCopiedNotification")
	static let callStatusConnecting = L10n("callStatusConnecting")
	static let callStatusDialing = L10n("callStatusDialing")
	static let callStatusDisconnected = L10n("callStatusDisconnected")
	static let callStatusDisconnecting = L10n("callStatusDisconnecting")
	static let callStatusEnded = L10n("callStatusEnded")
	static let cameraPermissionTitle = L10n("cameraPermissionTitle")
	static let copyApnsTokenAction = L10n("copyApnsTokenAction")
	static let copyApnsTokenHint = L10n("copyApnsTokenHint")
	static let microphonePermissionTitle = L10n("microphonePermissionTitle")
	static let outgoingCallAction = L10n("outgoingCallAction")
	static let outgoingCallHint = L10n("outgoingCallHint")
	static let permissionsLegend = L10n("permissionsLegend")
	static let redialAction = L10n("redialAction")
	static let roomAliasPlaceholder = L10n("roomAliasPlaceholder")
}

/// A backport of type-safe localizable strings for iOS 15.
extension String {
	init(localized key: L10n) {
		if #available(iOS 16, *) {
			self.init(
				localized: String.LocalizationValue(key.key),
				table: key.table
			)
		} else {
			self = NSLocalizedString(
				key.key,
				tableName: key.table,
				bundle: .main,
				comment: key.key
			)
		}
	}
}
