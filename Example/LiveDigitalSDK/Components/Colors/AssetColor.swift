import Foundation
import SwiftUI


enum AssetColor: String, CaseIterable, Identifiable {
	case contrast = "contrast"
	case secondaryBase = "secondary-base"
	case secondary01 = "secondary-01"
	case secondary02 = "secondary-02"
	case secondary03 = "secondary-03"
	case successBase = "success-base"
	case success01 = "success-01"
	case errorBase = "error-base"
	case error01 = "error-01"
	case accentBase = "accent-base"
	case accent01 = "accent-01"
	case accent02 = "accent-02"
	case accent03 = "accent-03"
	case grayout01 = "grayout-01"
	case grayout02 = "grayout-02"

	var id: String { rawValue }
	var color: Color { Color(rawValue) }
	var uiColor: UIColor { UIColor(resource: .init(name: rawValue, bundle: .main)) }
}

// MARK: - Preview implementation

#Preview("Colors") {
	VStack(spacing: 16) {
		ForEach(AssetColor.allCases) { assetColor in
			HStack(spacing: 12) {
				RoundedRectangle(cornerRadius: 8)
					.fill(assetColor.color)
					.frame(width: 50, height: 50)
					.overlay(
						RoundedRectangle(cornerRadius: 8)
							.stroke(Color.primary.opacity(0.2), lineWidth: 1)
					)
				Text(assetColor.rawValue)
					.font(.headline)
					.foregroundColor(.primary)
				Spacer()
			}
			.padding(.horizontal)
		}
	}
	.padding()
}
