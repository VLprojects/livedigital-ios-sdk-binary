import Foundation
import SwiftUI


struct RoundButton {
	private let config: RoundButtonConfig
	private let disabled: Bool
	private let size: CGFloat
	private let action: @MainActor () -> Void

	init(
		config: RoundButtonConfig,
		disabled: Bool = false,
		size: CGFloat = 50,
		action: @escaping @MainActor () -> Void
	) {
		self.config = config
		self.disabled = disabled
		self.size = size
		self.action = action
	}
}

// MARK: - View implementation

extension RoundButton: View {
	var body: some View {
		Button(action: action, label: {})
			.buttonStyle(config: config, size: size)
			.disabled(disabled)
	}
}

// MARK: - Private methods

extension Button {
	@ViewBuilder
	fileprivate func buttonStyle(config: RoundButtonConfig, size: CGFloat) -> some View {
		let style: RoundButtonStyle = switch config {
			case .accept: RoundButtonStyleAccept()
			case .reject: RoundButtonStyleReject()
			case .camera(let isOn): RoundButtonStyleMediaCapture(isOn: isOn, kind: .camera)
			case .microphone(let isOn): RoundButtonStyleMediaCapture(isOn: isOn, kind: .microphone)
			case .sound(let isOn): RoundButtonStyleMediaSound(isOn: isOn)
			case .custom(let icon, let text): RoundButtonStyleCustom(icon: icon, text: text)
		}
		let styledContent = RoundButtonStyledContent(
			buttonSize: size,
			config: config,
			style: style
		)
		self.buttonStyle(styledContent)
	}
}

// MARK: - Preview implementation

#Preview("RoundButton") {
	VStack {
		RoundedContainer {
			HStack(spacing: 16) {
				RoundButton(config: .accept, disabled: false, action: {})
				RoundButton(config: .reject, disabled: false, action: {})
			}
		}
		RoundedContainer {
			HStack(spacing: 16) {
				RoundButton(config: .camera(isOn: true), disabled: false, action: {})
				RoundButton(config: .camera(isOn: false), disabled: false, action: {})
			}
		}
		RoundedContainer {
			HStack(spacing: 16) {
				RoundButton(config: .microphone(isOn: true), disabled: false, action: {})
				RoundButton(config: .microphone(isOn: false), disabled: false, action: {})
			}
		}
		RoundedContainer {
			HStack(spacing: 16) {
				RoundButton(config: .sound(isOn: true), disabled: false, action: {})
				RoundButton(config: .sound(isOn: false), disabled: false, action: {})
			}
		}
		RoundedContainer {
			HStack(spacing: 16) {
				RoundButton(config: .custom(Image(.closeMini), nil), disabled: false, action: {})
				RoundButton(config: .custom(Image(.refresh), "Redial"), disabled: false, action: {})
			}
		}
	}
}
