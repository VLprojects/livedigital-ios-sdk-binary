import Foundation
import SwiftUI


enum AssetFont: String, CaseIterable, Identifiable {
	case mainTextMedium = "mainTextMedium"

	var id: String { rawValue }

	var font: Font {
		switch self {
			case .mainTextMedium: .custom("PTRootUI-Medium", size: 16)
		}
	}
}

// MARK: - Preview implementation

#Preview("Fonts") {
	VStack(spacing: 16) {
		ForEach(AssetFont.allCases) { assetFont in
			Text(assetFont.rawValue)
				.font(assetFont.font)
				.foregroundColor(.primary)
			Spacer()
		}
	}
	.padding()
}
