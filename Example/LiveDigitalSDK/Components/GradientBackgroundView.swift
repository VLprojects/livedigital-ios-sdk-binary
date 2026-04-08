import Foundation
import SwiftUI


struct GradientBackgroundView {
	private let colors: [Color]

	init(colors: [Color] = [AssetColor.accent02.color, AssetColor.accent01.color]) {
		self.colors = colors
	}
}

// MARK: - View implementation

extension GradientBackgroundView: View {
	var body: some View {
		LinearGradient(
			gradient: Gradient(colors: colors),
			startPoint: .top,
			endPoint: .bottom
		)
		.ignoresSafeArea()
	}
}

// MARK: - Preview implementation

#Preview("GradientBackgroundView") {
	GradientBackgroundView()
}
