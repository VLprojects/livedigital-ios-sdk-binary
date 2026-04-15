import Foundation


enum CallSessionStatus {
	case dialing
	case connecting
	case connected(Date)
	case disconnecting
	case disconnected
	case callEnded
}
