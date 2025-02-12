import Foundation


struct Room: Decodable {
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case channelId = "channelId"
	}

	let id: String
	let channelId: String
}
