import Foundation
import SwiftUI


struct RoundButtonStyleMediaCapture {
	enum MediaCaptureKind {
		case camera
		case microphone
	}

	let isOn: Bool
	let kind: MediaCaptureKind
}

// MARK: - RoundButtonStyle implementation

extension RoundButtonStyleMediaCapture: RoundButtonStyle {
	var sidePadding: CGFloat? {
		0
	}

	var icon: Image? {
		switch kind {
			case .camera: isOn ? Image(.cameraOn) : Image(.cameraOff)
			case .microphone: isOn ? Image(.microphoneOn) : Image(.microphoneOff)
		}
	}

	var text: String? {
		nil
	}

	func textColor(for state: ButtonStyleConfiguration) -> Color {
		iconColor(for: state)
	}

	func iconColor(for state: ButtonStyleConfiguration) -> Color {
		isOn ? AssetColor.accentBase.color : AssetColor.errorBase.color
	}

	func backgroundColor(for state: ButtonStyleConfiguration) -> Color {
		if isOn {
			state.isPressed ? AssetColor.accent03.color : AssetColor.contrast.color
		} else {
			state.isPressed ? AssetColor.accent03.color : AssetColor.grayout02.color
		}
	}
}
