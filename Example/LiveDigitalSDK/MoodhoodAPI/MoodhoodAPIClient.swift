import Foundation


protocol MoodhoodAPIClient {
	var isAuthorized: Bool { get }

	@discardableResult
	func authorizeAsGuest() async throws(APIClientError) -> MoodhoodUserToken

	func unauthorize()

	func createParticipant(
		space: String,
		room: String,
		clientUniqueId: String,
		role: String,
		name: String
	) async throws(APIClientError) -> MoodhoodParticipant

	func createSignalingToken(
		space: String,
		participant: String
	) async throws(APIClientError) -> SignalingToken

	func fetchRoom(
		roomAlias: String
	) async throws(APIClientError) -> Room

	func fetchRoom(
		space: String,
		room: String
	) async throws(APIClientError) -> Room

	func joinRoom(
		space: String,
		room: String,
		participant: String
	) async throws(APIClientError)
}
