import Foundation


protocol MoodhoodAPIClient {
	func authorizeAsGuest() async throws(MoodhoodAPIClientError) -> MoodhoodUserToken

	func createParticipant(
		userToken: MoodhoodUserToken,
		space: String,
		room: String,
		clientUniqueId: String,
		role: String,
		name: String
	) async throws(MoodhoodAPIClientError) -> MoodhoodParticipant

	func createSignalingToken(
		userToken: MoodhoodUserToken,
		space: String,
		participant: String
	) async throws(MoodhoodAPIClientError) -> SignalingToken

	func fetchRoom(
		userToken: MoodhoodUserToken,
		space: String,
		room: String
	) async throws(MoodhoodAPIClientError) -> Room

	func joinRoom(
		userToken: MoodhoodUserToken,
		space: String,
		room: String,
		participant: String
	) async throws(MoodhoodAPIClientError)
}
