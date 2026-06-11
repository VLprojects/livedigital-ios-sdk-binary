import Foundation
import SwiftUI


struct RoundButtonStyleCustom {
	let icon: Image?
	let text: String?
}

// MARK: - RoundButtonStyle implementation

extension RoundButtonStyleCustom: RoundButtonStyle {
	var sidePadding: CGFloat? {
		text == nil ? 0 : 16
	}

	func textColor(for state: ButtonStyleConfiguration) -> Color {
		iconColor(for: state)
	}

	func iconColor(for state: ButtonStyleConfiguration) -> Color {
		AssetColor.accentBase.color
	}

	func backgroundColor(for state: ButtonStyleConfiguration) -> Color {
		state.isPressed ? AssetColor.accent03.color : AssetColor.contrast.color
	}
}
