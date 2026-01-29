import Foundation


struct Call {
	let id: UUID
	let caller: String
	let roomAlias: String
	let direction: CallDirection
	var state: CallState
	var isMuted: Bool = false
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
