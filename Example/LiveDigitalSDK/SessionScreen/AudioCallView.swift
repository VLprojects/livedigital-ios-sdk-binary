import Foundation
import SwiftUI


struct AudioCallView {
	@ObservedObject var vm: AudioCallVM
}

// MARK: - View implementation

extension AudioCallView: View {
	var body: some View {
		ZStack {
			backgroundBlock

			VStack {
				if !vm.isInCall {
					Spacer()
				}
				nameBlock
				statusBlock
				Spacer()
				bottomPanelBlock
			}
			.padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
		}
	}
}

// MARK: - Private methods

private extension AudioCallView {
	var backgroundBlock: some View {
		let colors = vm.canRecall
			? [AssetColor.secondary03.color, AssetColor.secondary02.color]
			: [AssetColor.accent02.color, AssetColor.accent01.color]
		return GradientBackgroundView(colors: colors)
			.ignoresSafeArea()
	}

	var nameBlock: some View {
		RoundedContainer {
			Text(vm.companionName)
				.font(AssetFont.mainTextMedium.font)
				.foregroundStyle(AssetColor.contrast.color)
				.padding(.horizontal, 20)
		}
	}

	var statusBlock: some View {
		RoundedContainer {
			Text(vm.callStatusLabel)
				.font(AssetFont.mainTextMedium.font)
				.monospacedDigit()
				.foregroundStyle(AssetColor.contrast.color)
				.padding(.horizontal, 20)
		}
	}

	var bottomPanelBlock: some View {
		RoundedContainer {
			HStack {
				if vm.canRecall {
					recallButton
					Spacer()
					dismissButton
				} else {
					microphoneButton
					Spacer()
					endCallButton
				}
			}
			.frame(maxWidth: .infinity)
		}
		.frame(maxWidth: 440)
	}

	var recallButton: some View {
		RoundButton(
			config: .custom(Image(.refresh), String(localized: .recallAction)),
			action: {
				vm.recall()
			}
		)
	}

	var dismissButton: some View {
		RoundButton(
			config: .custom(Image(.closeMini), nil),
			action: {
				vm.dismiss()
			}
		)
	}


	var microphoneButton: some View {
		RoundButton(
			config: .microphone(isOn: vm.isMicrophoneOn),
			disabled: !vm.isInCall,
			action: {
				vm.toggleMicrophone()
			}
		)
	}

	var endCallButton: some View {
		RoundButton(
			config: .reject,
			disabled: vm.canFinishSession,
			action: {
				vm.finishSession()
			}
		)
	}
}
