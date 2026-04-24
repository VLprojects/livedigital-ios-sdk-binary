import Foundation
import UIKit
import SwiftUI


protocol QRGenerator {
	func generate(from string: String) -> UIImage?
	func generate(from string: String) -> Image?
}
