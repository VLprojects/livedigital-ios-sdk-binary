import Foundation
import SwiftUI


struct StartScreenView {
	@ObservedObject private var vm: StartScreenVM

	init(vm: StartScreenVM) {
		self.vm = vm
	}
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
		.overlay(alignment: .bottom) {
			NotificationsStack(vm: vm.notificationsVM)
				.padding(.horizontal)
		}
	}
}

// MARK: - Private methods

private extension StartScreenView {
	var apnsTokenBlock: some View {
		RoundedContainer {
			VStack {
				Text(.copyApnsTokenHint)
					.font(AssetFont.mainTextMedium.font)
					.foregroundStyle(AssetColor.contrast.color)
					.frame(maxWidth: .infinity, alignment: .leading)
				RoundButton(
					config: .custom(nil, String(localized: .copyApnsTokenAction)),
					disabled: !vm.apnsPermissionGranted,
					action: {
						vm.copyAPNSToken()
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
					.font(AssetFont.mainTextMedium.font)
					.foregroundStyle(AssetColor.contrast.color)
					.frame(maxWidth: .infinity, alignment: .leading)
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
			Toggle(isOn: apnsPermissionBinding) {
				Text(.apnsPermissionTitle)
					.font(AssetFont.mainTextMedium.font)
					.foregroundStyle(AssetColor.contrast.color)
				PermissionIndicator(type: .required)
			}
			.toggleStyle(LDToggleStyle())
		}
	}

	var cameraPermissionBlock: some View {
		HStack {
			Toggle(isOn: cameraPermissionBinding) {
				Text(.cameraPermissionTitle)
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
				Text(.microphonePermissionTitle)
					.font(AssetFont.mainTextMedium.font)
					.foregroundStyle(AssetColor.contrast.color)
				PermissionIndicator(type: .regular)
			}
			.toggleStyle(LDToggleStyle())
		}
	}

	var apnsPermissionBinding: Binding<Bool> {
		Binding(
			get: {
				vm.apnsPermissionGranted
			},
			set: { newValue in
				if newValue {
					vm.requestApnsPermission()
				}
			}
		)
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
