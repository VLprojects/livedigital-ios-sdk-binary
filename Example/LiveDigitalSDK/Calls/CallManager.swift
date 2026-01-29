import Combine
import Intents


protocol CallManager {
	var deviceToken: AnyPublisher<String?, Never> { get }
	var deviceTokenCurrentValue: String? { get }

	func addObserver(_ observer: any CallManagerObserver)
	func removeObserver(_ observer: any CallManagerObserver)

	func startCallFromIntent(_ intent: INIntent)
	func startCallManually(to roomAlias: String)
	func reportCallFailed(_ call: Call)
	func reportCallEnded(_ call: Call)
	func reportCallAnsweredOnOtherDevice(_ call: Call)
	func reportCallDeclined(_ call: Call)
}
