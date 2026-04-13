import SwiftUI


class NotificationsVM: ObservableObject {
	private enum Config {
		static let autoHideTime: TimeInterval = 5
	}

	@Published var notifications = [NotificationContent]()

	func show(_ text: String) {
		let notification = NotificationContent(text: text)
		notifications.append(notification)
		DispatchQueue.main.asyncAfter(deadline: .now() + Config.autoHideTime) { [weak self] in
			self?.notifications.removeAll { item in
				item.id == notification.id
			}
		}
	}
}

