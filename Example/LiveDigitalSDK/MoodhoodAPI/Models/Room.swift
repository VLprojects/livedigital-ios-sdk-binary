import Foundation


struct Room: Decodable {
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
		case alias = "alias"
		case spaceId = "spaceId"
		case channelId = "channelId"
	}

	let id: String
	let alias: String
	let spaceId: String
	let channelId: String
	let name: String
}
