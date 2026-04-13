import Foundation


@MainActor
final class AudioCallVM: ObservableObject {
	@Published var isSoundOn = true
	@Published var isMicrophoneOn = true
	@Published var companionName: String = "Room / Contact name"
	@Published var callStatus: String = "00:01"

	private let callManager: CallManager?
	private let apiClient: MoodhoodAPIClient

	init(callManager: CallManager?, apiClient: MoodhoodAPIClient) {
		self.callManager = callManager
		self.apiClient = apiClient

		callManager?.addObserver(self)
	}

	deinit {
		callManager?.removeObserver(self)
	}
}

// MARK: - Internal methods

internal extension AudioCallVM {
	func toggleSound() {
	}

	func toggleMicrophone() {
	}

	func endCall() {
	}
}

// MARK: - CallManagerObserver implementation

extension AudioCallVM: CallManagerObserver {
}

// MARK: - Private methods

private extension AudioCallVM {
}
