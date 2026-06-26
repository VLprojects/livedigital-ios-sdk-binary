import Foundation
import SwiftUI


struct ConferenceStartScreenView {
	@ObservedObject private var vm: ConferenceStartScreenVM

	init(vm: ConferenceStartScreenVM) {
		self.vm = vm
	}
}

// MARK: - View implementation

extension ConferenceStartScreenView: View {
	var body: some View {
		ZStack {
			GradientBackgroundView()
				.ignoresSafeArea()
			ScrollView {
				VStack(spacing: 16) {
					openRoomBlock
					permissionsBlock
				}
			}
			.frame(maxWidth: 600)
		}
		.overlay(alignment: .bottom) {
			NotificationsStack(vm: vm.notificationsVM)
				.padding(.horizontal)
		}
	}
}

// MARK: - Private methods

private extension ConferenceStartScreenView {
	var openRoomBlock: some View {
		RoundedContainer {
			VStack(spacing: 20) {
				Text(String(localized: .openRoomHint))
					.font(AssetFont.mainTextMedium.font)
					.foregroundStyle(AssetColor.contrast.color)
					.frame(maxWidth: .infinity, alignment: .leading)
				HStack {
					ZStack(alignment: .leading) {
						if vm.roomAlias.isEmpty {
							Text(String(localized: .roomAliasPlaceholder))
								.font(AssetFont.mainTextMedium.font)
								.foregroundStyle(AssetColor.secondary02.color)
								.frame(maxWidth: .infinity, alignment: .leading)
						}
						TextField(String(localized: .roomAliasPlaceholder), text: $vm.roomAlias)
							.font(AssetFont.mainTextMedium.font)
							.foregroundStyle(AssetColor.contrast.color)
							.frame(maxWidth: .infinity, alignment: .leading)
							.overlay(
								Rectangle()
									.frame(height: 1)
									.foregroundStyle(AssetColor.contrast.color),
								alignment: .bottom
							)
					}
					RoundButton(
						config: .custom(nil, String(localized: .openRoomAction)),
						disabled: !vm.canJoinRoom,
						action: {
							vm.joinRoom()
						}
					)
				}
			}
			.frame(maxWidth: .infinity)
		}
		.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
	}

	var permissionsBlock: some View {
		RoundedContainer {
			VStack(spacing: 20) {
				Text(String(localized: .permissionsLegend))
					.font(AssetFont.mainTextMedium.font)
					.foregroundStyle(AssetColor.contrast.color)
					.frame(maxWidth: .infinity, alignment: .leading)
				cameraPermissionBlock
				microphonePermissionBlock
			}
			.frame(maxWidth: .infinity)
		}
		.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
	}

	var cameraPermissionBlock: some View {
		HStack {
			Toggle(isOn: cameraPermissionBinding) {
				Text(String(localized: .cameraPermissionTitle))
					.font(AssetFont.mainTextMedium.font)
					.foregroundStyle(AssetColor.contrast.color)
				PermissionIndicator(type: .regular)
			}
			.toggleStyle(LDToggleStyle())
		}
	}

	var microphonePermissionBlock: some View {
		HStack {
			Toggle(isOn: microphonePermissionBinding) {
				Text(String(localized: .microphonePermissionTitle))
					.font(AssetFont.mainTextMedium.font)
					.foregroundStyle(AssetColor.contrast.color)
				PermissionIndicator(type: .required)
			}
			.toggleStyle(LDToggleStyle())
		}
	}

	var cameraPermissionBinding: Binding<Bool> {
		Binding(
			get: {
				vm.cameraPermissionGranted
			},
			set: { newValue in
				if newValue {
					vm.requestCameraPermission()
				}
			}
		)
	}

	var microphonePermissionBinding: Binding<Bool> {
		Binding(
			get: {
				vm.microphonePermissionGranted
			},
			set: { newValue in
				if newValue {
					vm.requestMicrophonePermission()
				}
			}
		)
	}
}
