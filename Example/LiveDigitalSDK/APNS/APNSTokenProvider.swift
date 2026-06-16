import Foundation
import Combine


protocol APNSTokenProvider {
	var deviceToken: AnyPublisher<String?, Never> { get }
	var deviceTokenCurrentValue: String? { get }
}
