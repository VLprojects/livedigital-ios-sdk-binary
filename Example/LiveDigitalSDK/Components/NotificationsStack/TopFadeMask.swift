import SwiftUI


struct TopFadeMask: ViewModifier {
	var height: CGFloat
	var active: Bool

	func body(content: Content) -> some View {
		content.mask(
			VStack(spacing: 0) {
				if active {
					LinearGradient(
						colors: [.clear, .black],
						startPoint: .top,
						endPoint: .bottom
					)
					.frame(height: height)
				}

				Rectangle().fill(.black)
			}
		)
	}
}
