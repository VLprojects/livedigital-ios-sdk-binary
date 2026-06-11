import Foundation


enum CallSessionStatus: Equatable {
	case dialing
	case connecting
	case connected(Date)
	case disconnecting
	case disconnected
	case callEnded
}
