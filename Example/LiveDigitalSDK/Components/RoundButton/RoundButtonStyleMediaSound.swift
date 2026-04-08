import Foundation
import SwiftUI


struct RoundButtonStyleMediaSound {
	let isOn: Bool
}

// MARK: - RoundButtonStyle implementation

extension RoundButtonStyleMediaSound: RoundButtonStyle {
	var sidePadding: CGFloat? {
		0
	}

	var icon: Image? {
		Image(.sound)
	}

	var text: String? {
		nil
	}

	func textColor(for state: ButtonStyleConfiguration) -> Color {
		iconColor(for: state)
	}

	func iconColor(for state: ButtonStyleConfiguration) -> Color {
		isOn ? AssetColor.accentBase.color : AssetColor.contrast.color
	}

	func backgroundColor(for state: ButtonStyleConfiguration) -> Color {
		if isOn {
			state.isPressed ? AssetColor.accent03.color : AssetColor.contrast.color
		} else {
			state.isPressed ? AssetColor.accent03.color : AssetColor.grayout02.color
		}
	}
}
