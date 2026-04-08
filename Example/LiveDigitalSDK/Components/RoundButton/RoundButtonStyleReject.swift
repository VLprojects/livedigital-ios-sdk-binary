import Foundation
import SwiftUI


struct RoundButtonStyleReject {
}

// MARK: - RoundButtonStyle implementation

extension RoundButtonStyleReject: RoundButtonStyle {
	var sidePadding: CGFloat? {
		0
	}

	var icon: Image? {
		Image(.closeMini)
	}

	var text: String? {
		nil
	}

	func textColor(for state: ButtonStyleConfiguration) -> Color {
		iconColor(for: state)
	}

	func iconColor(for state: ButtonStyleConfiguration) -> Color {
		AssetColor.contrast.color
	}

	func backgroundColor(for state: ButtonStyleConfiguration) -> Color {
		state.isPressed ? AssetColor.error01.color : AssetColor.errorBase.color
	}
}
