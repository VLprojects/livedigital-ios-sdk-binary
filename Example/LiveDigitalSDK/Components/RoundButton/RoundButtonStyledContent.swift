import Foundation
import SwiftUI


struct RoundButtonStyledContent {
	let buttonSize: CGFloat
	let config: RoundButtonConfig
	let style: RoundButtonStyle

	@Environment(\.isEnabled) private var isEnabled
}

// MARK: - ButtonStyle implementation

extension RoundButtonStyledContent: ButtonStyle {
	public func makeBody(configuration: Configuration) -> some View {
		makeButtonBody(configuration)
			.frame(height: buttonSize)
			.frame(minWidth: buttonSize)
		.background(
			style.backgroundColor(for: configuration)
				.cornerRadius(buttonSize / 2)
		)
		/// A tappable area of a plain button style doesn't include an empty space. Only the button's content, like text or image, can respond to user interaction.
		/// So, tapping on an empty space in a plain button style won't trigger an action.
		/// To make the whole area of a plain button tappable, we need to explicitly define a new tappable area.
		/// The content Shape() modifier lets define the new shape for the tappable area.
		.contentShape(Rectangle())
	}
}
// MARK: - Private methods

private extension RoundButtonStyledContent {
	func makeButtonBody(_ configuration: Configuration) -> some View {
		return HStack(alignment: .center, spacing: 0) {
			Spacer()
				.frame(width: style.sidePadding)
			if let icon = style.icon {
				icon
					.renderingMode(.template)
					.foregroundStyle(style.iconColor(for: configuration))
			}
			if let text = style.text {
				Text(text)
					.font(AssetFont.mainTextMedium.font)
					.foregroundColor(style.textColor(for: configuration))
					.truncationMode(.tail)
					.lineLimit(1)
					.padding(.horizontal, 4)
					.layoutPriority(0)
			}
			Spacer()
				.frame(width: style.sidePadding)
		}
		.opacity(isEnabled ? 1.0 : 0.5)
		.saturation(isEnabled ? 1.0 : 0.0)
	}
}
