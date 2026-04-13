import Foundation


enum CallSessionStatus {
	case connecting
	case connected(Date)
	case disconnecting
	case disconnected
}
