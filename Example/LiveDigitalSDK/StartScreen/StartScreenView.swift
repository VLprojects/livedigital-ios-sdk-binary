import Foundation
import SwiftUI


struct StartScreenView {
	@State var apnsPermissionGranted = false
	@State var microphonePermissionGranted = false
	@State var cameraPermissionGranted = false
}

// MARK: - View implementation

extension StartScreenView: View {
	var body: some View {
		ZStack {
			GradientBackgroundView()
				.ignoresSafeArea()
			ScrollView {
				VStack(spacing: 16) {
					apnsTokenBlock
					permissionsBlock
				}
			}
		}
	}
}

// MARK: - Private methods

private extension StartScreenView {
	var apnsTokenBlock: some View {
		RoundedContainer {
			VStack {
				Text(.copyApnsTokenHint)
					.foregroundStyle(AssetColor.contrast.color)
				RoundButton(
					config: .custom(nil, String(localized: .copyApnsTokenAction)),
					action: {
					}
				)
			}
			.frame(maxWidth: .infinity)
		}
		.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
	}

	var permissionsBlock: some View {
		RoundedContainer {
			VStack(spacing: 20) {
				Text(.permissionsLegend)
					.foregroundStyle(AssetColor.contrast.color)
				apnsPermissionBlock
				cameraPermissionBlock
				microphonePermissionBlock
			}
			.frame(maxWidth: .infinity)
		}
		.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
	}

	var apnsPermissionBlock: some View {
		HStack {
			Toggle(isOn: $apnsPermissionGranted) {
				Text(.apnsPermissionTitle)
					.foregroundStyle(AssetColor.contrast.color)
				PermissionIndicator(type: .required)
			}
			.toggleStyle(LDToggleStyle())
		}
	}

	var cameraPermissionBlock: some View {
		HStack {
			Toggle(isOn: $cameraPermissionGranted) {
				Text(.cameraPermissionTitle)
					.foregroundStyle(AssetColor.contrast.color)
				PermissionIndicator(type: .regular)
			}
			.toggleStyle(LDToggleStyle())
		}
	}

	var microphonePermissionBlock: some View {
		HStack {
			Toggle(isOn: $microphonePermissionGranted) {
				Text(.microphonePermissionTitle)
					.foregroundStyle(AssetColor.contrast.color)
				PermissionIndicator(type: .regular)
			}
			.toggleStyle(LDToggleStyle())
		}
	}
}

// MARK: - Preview implementation

#Preview {
	StartScreenView()
}
