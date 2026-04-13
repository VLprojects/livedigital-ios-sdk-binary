import SwiftUI


struct NotificationView {
	let text: String
}

// MARK: - View implementation

extension NotificationView: View {
	var body: some View {
		RoundedContainer(padding: EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)) {
			Text(text)
				.multilineTextAlignment(.leading)
				.font(AssetFont.mainTextMedium.font)
				.foregroundStyle(AssetColor.contrast.color)
		}
	}
}

#Preview("NotificationsStack") {
	GradientBackgroundView()
		.overlay(alignment: .bottom) {
			NotificationView(text: "Some notification")
		}
}
