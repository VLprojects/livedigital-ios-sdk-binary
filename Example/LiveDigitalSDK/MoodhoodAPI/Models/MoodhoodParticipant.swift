import Foundation


struct MoodhoodParticipant: Decodable {
	enum CodingKeys: String, CodingKey {
		case id = "id"
	}

	let id: String
}
