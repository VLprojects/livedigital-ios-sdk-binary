import Foundation
import SwiftUI


struct RoundedContainer<Content: View> {
	private let radius: CGFloat
	private let padding: EdgeInsets
	private let fillColor: Color
	private let content: Content

	init(
		radius: CGFloat = 16,
		padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
		fillColor: Color = AssetColor.grayout01.color,
		@ViewBuilder content: () -> Content
	) {
		self.radius = radius
		self.padding = padding
		self.fillColor = fillColor
		self.content = content()
	}
}

// MARK: - View implementation

extension RoundedContainer: View {
	var body: some View {
		content
			.padding(padding)
			.background(
				RoundedRectangle(cornerRadius: radius)
					.fill(fillColor)
			)
	}
}

// MARK: - Preview implementation

#Preview("RoundedContainer") {
	RoundedContainer {
		Text("Hello")
			.foregroundStyle(AssetColor.contrast.color)
	}
}
