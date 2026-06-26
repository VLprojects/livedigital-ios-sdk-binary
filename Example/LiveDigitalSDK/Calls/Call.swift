import Foundation


struct Call {
	let id: UUID
	let caller: String
	let signalingToken: String
	let direction: CallDirection
	var state: CallState
	var isMuted: Bool = false

	func withState(_ newState: CallState) -> Call {
		Call(
			id: id,
			caller: caller,
			signalingToken: signalingToken,
			direction: direction,
			state: newState,
			isMuted: isMuted
		)
	}
}


extension Call {
	enum CallDirection: Hashable, Equatable {
		case incoming
		case outgoing
	}

	enum CallState: Hashable, Equatable {
		case new
		case connecting
		case active
		case ended
	}
}
