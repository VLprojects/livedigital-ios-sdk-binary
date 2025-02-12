import Foundation


struct MoodhoodUserToken: Decodable {
	enum CodingKeys: String, CodingKey {
		case tokenType = "token_type"
		case accessToken = "access_token"
		case refreshToken = "refresh_token"
	}

	let tokenType: String
	let accessToken: String
	let refreshToken: String
}
