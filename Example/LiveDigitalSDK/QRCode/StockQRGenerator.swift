import Foundation
import UIKit
import SwiftUI
import CoreImage.CIFilterBuiltins


final class StockQRGenerator {
	private let context = CIContext()
	private let filter = CIFilter.qrCodeGenerator()
}

// MARK: - QRGenerator implementation

extension StockQRGenerator: QRGenerator {
	func generate(from string: String) -> UIImage? {
		guard let cgImage = generateCGImage(from: string) else {
			return nil
		}
		return UIImage(cgImage: cgImage)
	}

	func generate(from string: String) -> Image? {
		guard let cgImage = generateCGImage(from: string) else {
			return nil
		}
		return Image(cgImage, scale: 1, label: Text(string))
			.interpolation(.none)
			.resizable(resizingMode: .stretch)
	}
}

// MARK: - Private methods

private extension StockQRGenerator {
	func generateCGImage(from string: String) -> CGImage? {
		filter.message = Data(string.utf8)
		guard let outputImage = filter.outputImage else {
			return nil
		}
		return context.createCGImage(outputImage, from: outputImage.extent)
	}
}
