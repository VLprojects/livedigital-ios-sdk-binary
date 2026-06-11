import Foundation
import SwiftUI


enum RoundButtonConfig {
	case accept
	case reject
	case camera(isOn: Bool)
	case microphone(isOn: Bool)
	case sound(isOn: Bool)
	case custom(Image?, String?)
}
