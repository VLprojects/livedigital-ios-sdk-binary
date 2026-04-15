import Combine
import Intents


protocol CallManager {
	var deviceToken: AnyPublisher<String?, Never> { get }
	var deviceTokenCurrentValue: String? { get }

	func addObserver(_ observer: any CallManagerObserver)
	func removeObserver(_ observer: any CallManagerObserver)

	func toggleMicrophone(muted: Bool, in call: Call)

	func startCallFromIntent(_ intent: INIntent)
	func startCallManually(to roomAlias: String)
	func endCall(_ call: Call)
	func endCall(_ callId: UUID)

	func reportCallFailed(_ call: Call)
	func reportCallEnded(_ call: Call)
	func reportCallAnsweredOnOtherDevice(_ call: Call)
	func reportCallDeclined(_ call: Call)
}
