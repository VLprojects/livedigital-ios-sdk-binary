import Foundation


struct SignalingToken: Decodable {
	enum CodingKeys: String, CodingKey {
		case signalingToken = "signalingToken"
	}

	let signalingToken: String
}
