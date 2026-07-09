import Foundation
import SwiftUI


struct FlowSelectionView {
	let onSelect: (_ flow: AppWorkflow) -> Void
}

// MARK: - View implementation

extension FlowSelectionView: View {
	var body: some View {
		ZStack {
			GradientBackgroundView()
				.ignoresSafeArea()
			ScrollView {
				VStack(spacing: 16) {
					flowSelectionBlock
				}
			}
			.frame(maxWidth: 600)
		}
	}
}

// MARK: - Private methods

private extension FlowSelectionView {
	var flowSelectionBlock: some View {
		RoundedContainer {
			VStack(spacing: 20) {
				Text(String(localized: .flowSelectionHint))
					.font(AssetFont.mainTextMedium.font)
					.foregroundStyle(AssetColor.contrast.color)
					.frame(maxWidth: .infinity, alignment: .leading)
				RoundButton(
					config: .custom(nil, String(localized: .selectCallWorkflow)),
					action: {
						onSelect(.call)
					}
				)
				RoundButton(
					config: .custom(nil, String(localized: .selectConferenceWorkflow)),
					action: {
						onSelect(.conference)
					}
				)
			}
			.frame(maxWidth: .infinity)
		}
		.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
	}
}
