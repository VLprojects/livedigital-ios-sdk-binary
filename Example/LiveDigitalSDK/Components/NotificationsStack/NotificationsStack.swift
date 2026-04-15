import SwiftUI


struct NotificationsStack {
	private enum Config {
		static let fadeHeight: CGFloat = 40
		static let maxNotificationsCount = 6
	}

	@ObservedObject var vm: NotificationsVM
}

// MARK: - View implementation

extension NotificationsStack: View {
	var body: some View {
		VStack {
			ForEach(vm.notifications.suffix(Config.maxNotificationsCount), id: \.self) { notification in
				NotificationView(text: notification.text)
					.id(notification.id)
					.fixedSize(horizontal: false, vertical: true)
					.layoutPriority(1)
					.transition(
						.asymmetric(
							insertion: .move(edge: .bottom).combined(with: .opacity),
							removal: .identity
						)
					)
			}
		}
		.frame(maxWidth: .infinity)
		.clipped()
		.animation(.easeOut(duration: 0.2), value: vm.notifications.count)
		.modifier(
			TopFadeMask(height: Config.fadeHeight, active: vm.notifications.count >= Config.maxNotificationsCount)
		)
	}
}

@available(iOS 17.0, *)
#Preview("NotificationsStack") {
	@Previewable @State var vm = NotificationsVM()

	GradientBackgroundView()
		.overlay(alignment: .bottom) {
			NotificationsStack(vm: vm)
			.padding(.horizontal)
		}
		.onTapGesture {
			func placeholderText(words: Int) -> String {
				let pool = ["lorem", "ipsum", "dolor", "sit", "amet"]
				return (0..<words)
					.map { _ in pool.randomElement()! }
					.joined(separator: " ")
			}
			vm.show(placeholderText(words: Int.random(in: 8...15)))
		}
}

