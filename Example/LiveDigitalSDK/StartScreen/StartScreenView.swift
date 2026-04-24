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
					makeCallBlock
					apnsTokenBlock
					permissionsBlock
				}
			}
			.frame(maxWidth: 600)
		}
		.overlay(alignment: .bottom) {
			NotificationsStack(vm: vm.notificationsVM)
				.padding(.horizontal)
		}
		.fullScreenCover(isPresented: Binding(get: {
			vm.presentedImage != nil
		}, set: { value in
			if !value {
				vm.presentedImage = nil
			}
		}), content: {
			if let image = vm.presentedImage {
				ZStack {
					Color.black
						.ignoresSafeArea()
					image
						.interpolation(.none)
						.aspectRatio(contentMode: .fit)
						.frame(maxWidth: .infinity, maxHeight: .infinity)
				}
				.contentShape(Rectangle())
				.onTapGesture {
					vm.presentedImage = nil
				}
			}
		})
	}
}

// MARK: - Private methods

private extension StartScreenView {
	var makeCallBlock: some View {
		RoundedContainer {
			VStack(spacing: 20) {
				Text(String(localized: .outgoingCallHint))
					.font(AssetFont.mainTextMedium.font)
					.foregroundStyle(AssetColor.contrast.color)
					.frame(maxWidth: .infinity, alignment: .leading)
				HStack {
					ZStack(alignment: .leading) {
						if vm.outgoingCallRoomAlias.isEmpty {
							Text(String(localized: .roomAliasPlaceholder))
								.font(AssetFont.mainTextMedium.font)
								.foregroundStyle(AssetColor.secondary02.color)
								.frame(maxWidth: .infinity, alignment: .leading)
						}
						TextField(String(localized: .roomAliasPlaceholder), text: $vm.outgoingCallRoomAlias)
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
						config: .custom(nil, String(localized: .outgoingCallAction)),
						disabled: !vm.canInitiateCall,
						action: {
							vm.initiateCall()
						}
					)
				}
			}
			.frame(maxWidth: .infinity)
		}
		.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
	}

	var apnsTokenBlock: some View {
		RoundedContainer {
			VStack {
				Text(String(localized: .copyApnsTokenHint))
					.font(AssetFont.mainTextMedium.font)
					.foregroundStyle(AssetColor.contrast.color)
					.frame(maxWidth: .infinity, alignment: .leading)
				HStack {
					RoundButton(
						config: .custom(nil, String(localized: .copyApnsTokenAction)),
						disabled: !vm.apnsPermissionGranted,
						action: {
							vm.copyAPNSToken()
						}
					)
					RoundButton(
						config: .custom(Image(systemName: "qrcode.viewfinder"), nil),
						disabled: !vm.apnsPermissionGranted,
						action: {
							vm.presentAPNSToken()
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
				Text(String(localized: .apnsPermissionTitle))
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
