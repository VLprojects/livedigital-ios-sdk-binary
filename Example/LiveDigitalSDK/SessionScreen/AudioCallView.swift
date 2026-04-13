import Foundation
import SwiftUI


struct AudioCallView {
	@ObservedObject var vm: AudioCallVM
}

// MARK: - View implementation

extension AudioCallView: View {
	var body: some View {
		ZStack {
			GradientBackgroundView()
				.ignoresSafeArea()

			VStack {
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
			Text(vm.callStatus)
				.font(AssetFont.mainTextMedium.font)
				.monospacedDigit()
				.foregroundStyle(AssetColor.contrast.color)
				.padding(.horizontal, 20)
		}
	}

	var bottomPanelBlock: some View {
		RoundedContainer {
			HStack {
				speakerButton
				Spacer()
				microphoneButton
				Spacer()
				endCallButton
			}
			.frame(maxWidth: .infinity)
		}
	}

	var speakerButton: some View {
		RoundButton(
			config: .sound(isOn: vm.isSoundOn),
			action: {
				vm.toggleSound()
			}
		)
	}

	var microphoneButton: some View {
		RoundButton(
			config: .microphone(isOn: vm.isMicrophoneOn),
			action: {
				vm.toggleMicrophone()
			}
		)
	}

	var endCallButton: some View {
		RoundButton(
			config: .reject,
			action: {
				vm.endCall()
			}
		)
	}
}
