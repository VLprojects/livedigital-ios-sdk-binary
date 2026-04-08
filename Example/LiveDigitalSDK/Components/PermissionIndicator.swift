import Foundation
import SwiftUI


struct PermissionIndicator {
	enum PermissionType {
		case required
		case regular
	}

	private let size: CGFloat
	private let type: PermissionType

	init(
		size: CGFloat = 8,
		type: PermissionType
	) {
		self.size = size
		self.type = type
	}
}

// MARK: - View implementation

extension PermissionIndicator: View {
	var body: some View {
		Circle()
			.foregroundStyle(fillColor)
			.frame(width: size, height: size)
	}
}

// MARK: - Private methods

private extension PermissionIndicator {
	var fillColor: Color {
		switch type {
			case .required: AssetColor.errorBase.color
			case .regular: AssetColor.secondary02.color
		}
	}
}



// MARK: - Preview implementation

#Preview("PermissionIndicator") {
	RoundedContainer {
		VStack {
			HStack {
				Text("Notifications")
					.foregroundStyle(AssetColor.contrast.color)
				PermissionIndicator(type: .required)
				Spacer()
			}

			HStack {
				Text("Camera")
					.foregroundStyle(AssetColor.contrast.color)
				PermissionIndicator(type: .regular)
				Spacer()
			}
		}
	}
	.padding()
}
