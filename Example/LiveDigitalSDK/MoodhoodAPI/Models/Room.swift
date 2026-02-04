import Foundation


struct Room: Decodable {
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case spaceId = "spaceId"
		case channelId = "channelId"
	}

	let id: String
	let spaceId: String
	let channelId: String
}
