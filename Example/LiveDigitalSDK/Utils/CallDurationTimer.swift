import Foundation
import Combine


final class CallDurationTimer {
	private var callDurationTimerCancellable: AnyCancellable?
	@Published private var durationText = String()
	@Published private(set) var callStatusLabel = String()
	@Published private(set) var isInCall = false
	@Published var callStatus: CallSessionStatus {
		didSet {
			handleStatusChange()
		}
	}

	init() {
		callStatus = .disconnected
		bindCallStatus()
	}
}

// MARK: - Private methods

private extension CallDurationTimer {
	static func callDurationText(_ duration: TimeInterval) -> String {
		let seconds = Int(duration.rounded(.awayFromZero))
		let h = seconds / 3600
		let m = (seconds % 3600) / 60
		let s = seconds % 60
		if h > 0 {
			return String(format: "%d:%02d:%02d", h, m, s)
		} else {
			return String(format: "%02d:%02d", m, s)
		}
	}

	static func callStatusText(for status: CallSessionStatus, durationText: String) -> String {
		switch status {
			case .dialing: String(localized: .callStatusDialing)
			case .connecting: String(localized: .callStatusConnecting)
			case .connected: durationText
			case .disconnecting: String(localized: .callStatusDisconnecting)
			case .disconnected: String(localized: .callStatusDisconnected)
			case .callEnded: String(localized: .callStatusEnded)
		}
	}

	static func isInCall(for status: CallSessionStatus) -> Bool {
		switch status {
			case .dialing: false
			case .connecting: true
			case .connected: true
			case .disconnecting: true
			case .disconnected: true
			case .callEnded: false
		}
	}

	func startTimer(from startDate: Date) {
		callDurationTimerCancellable?.cancel()
		durationText = Self.callDurationText(Date.now.timeIntervalSince(startDate))

		callDurationTimerCancellable = Timer
			.publish(every: 1, on: .main, in: .common)
			.autoconnect()
			.map { _ in Date().timeIntervalSince(startDate) }
			.sink { [weak self] elapsed in
				guard let self else { return }
				self.durationText = Self.callDurationText(elapsed)
			}
	}

	func stopTimer() {
		callDurationTimerCancellable?.cancel()
		callDurationTimerCancellable = nil
	}

	func handleStatusChange() {
		switch callStatus {
			case .connected(let startDate):
				startTimer(from: startDate)
			case .connecting, .disconnecting, .disconnected, .dialing, .callEnded:
				stopTimer()
		}
	}

	func bindCallStatus() {
		Publishers.CombineLatest($callStatus, $durationText)
			.map { (callStatus, callDuration) in
				Self.callStatusText(for: callStatus, durationText: callDuration)
			}
			.assign(to: &$callStatusLabel)

		$callStatus
			.map { Self.isInCall(for: $0) }
			.assign(to: &$isInCall)
	}
}
