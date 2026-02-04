import Foundation
import UIKit
import CoreImage.CIFilterBuiltins


final class StockQRGenerator {
	private let context = CIContext()
	private let filter = CIFilter.qrCodeGenerator()
}

// MARK: - QRGenerator implementation

extension StockQRGenerator: QRGenerator {
	func generate(from string: String) -> UIImage? {
		filter.message = Data(string.utf8)
		guard let outputImage = filter.outputImage else {
			return nil
		}
		guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
			return nil
		}
		return UIImage(cgImage: cgImage)
	}
}
