import Foundation


enum CallPushAction: String {
	case start = "call_start"
	case end = "call_end"
	case answered = "call_answered"
	case declinedByCallee = "call_declined_by_callee"
	case cancelled = "call_cancelled"
}
