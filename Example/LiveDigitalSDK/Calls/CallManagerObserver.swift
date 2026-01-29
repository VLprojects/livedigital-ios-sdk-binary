import Foundation
import AVFAudio


protocol CallManagerObserver: AnyObject {
	func didReceiveCall(_ call: Call)
	func didInitiateCall(_ call: Call)
	func didEndCall(_ call: Call)
	func didUpdateCallMuteState(_ call: Call)
	func didUpdateAudioSession(_ audioSession: AVAudioSession, active: Bool)
}

extension CallManagerObserver {
	func didReceiveCall(_ call: Call) {}
	func didInitiateCall(_ call: Call) {}
	func didEndCall(_ call: Call) {}
	func didUpdateCallMuteState(_ call: Call) {}
	func didUpdateAudioSession(_ audioSession: AVAudioSession, active: Bool) {}
}
