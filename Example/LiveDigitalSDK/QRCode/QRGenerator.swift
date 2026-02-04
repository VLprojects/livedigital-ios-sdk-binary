import Foundation
import UIKit


protocol QRGenerator {
	func generate(from string: String) -> UIImage?
}
