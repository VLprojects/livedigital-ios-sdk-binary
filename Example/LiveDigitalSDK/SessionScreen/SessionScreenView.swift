import Foundation
import SwiftUI


struct SessionScreenView {
	@State var isSoundOn = true
	@State var isMicrophoneOn = true
	@State var companionName: String = "Room / Contact name"
	@State var callStatus: String = "00:01"
}

// MARK: - View implementation

extension SessionScreenView: View {
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

private extension SessionScreenView {
	var nameBlock: some View {
		RoundedContainer {
			Text(companionName)
				.font(AssetFont.mainTextMedium.font)
				.foregroundStyle(AssetColor.contrast.color)
				.padding(.horizontal, 20)
		}
	}

	var statusBlock: some View {
		RoundedContainer {
			Text(callStatus)
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
			config: .sound(isOn: isSoundOn),
			action: {
				isSoundOn.toggle()
			}
		)
	}

	var microphoneButton: some View {
		RoundButton(
			config: .microphone(isOn: isMicrophoneOn),
			action: {
				isMicrophoneOn.toggle()
			}
		)
	}

	var endCallButton: some View {
		RoundButton(
			config: .reject,
			action: {
			}
		)
	}
}

// MARK: - Preview implementation

#Preview {
	SessionScreenView()
}
