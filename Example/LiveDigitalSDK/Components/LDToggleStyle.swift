import Foundation
import SwiftUI


struct LDToggleStyle {
}

// MARK: - ToggleStyle implementation

extension LDToggleStyle: ToggleStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
		Spacer()
		RoundedRectangle(cornerRadius: 12)
			.fill(configuration.isOn ? AssetColor.accentBase.color : AssetColor.secondary03.color)
			.overlay {
				Circle()
					.fill(.white)
					.padding(4)
					.offset(x: configuration.isOn ? 10 : -10)
			}
			.frame(width: 42, height: 24)
			.onTapGesture {
				withAnimation(.spring()) {
					configuration.isOn.toggle()
				}
			}
	}
}

// MARK: - Preview implementation

#Preview("LDToggleStyle") {
	@Previewable @State var isOn = false

	RoundedContainer {
		HStack {
			Toggle(isOn: $isOn) {
				Text(.apnsPermissionTitle)
					.foregroundStyle(AssetColor.contrast.color)
				PermissionIndicator(type: .required)
			}
			.toggleStyle(LDToggleStyle())
		}
	}
	.padding()
}
