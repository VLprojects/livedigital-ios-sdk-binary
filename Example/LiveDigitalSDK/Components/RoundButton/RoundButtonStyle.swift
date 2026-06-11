import Foundation
import SwiftUI


protocol RoundButtonStyle {
	var icon: Image? { get }
	var text: String? { get }
	var sidePadding: CGFloat? { get }
	func textColor(for state: ButtonStyleConfiguration) -> Color
	func iconColor(for state: ButtonStyleConfiguration) -> Color
	func backgroundColor(for state: ButtonStyleConfiguration) -> Color
}
