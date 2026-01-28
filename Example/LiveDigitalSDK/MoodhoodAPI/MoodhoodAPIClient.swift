import Foundation


protocol MoodhoodAPIClient {
	var isAuthorized: Bool { get }

	@discardableResult
	func authorizeAsGuest() async throws(MoodhoodAPIClientError) -> MoodhoodUserToken

	func unauthorize()

	func createParticipant(
		space: String,
		room: String,
		clientUniqueId: String,
		role: String,
		name: String
	) async throws(MoodhoodAPIClientError) -> MoodhoodParticipant

	func createSignalingToken(
		space: String,
		participant: String
	) async throws(MoodhoodAPIClientError) -> SignalingToken

	func fetchRoom(
		roomAlias: String
	) async throws(MoodhoodAPIClientError) -> Room

	func fetchRoom(
		space: String,
		room: String
	) async throws(MoodhoodAPIClientError) -> Room

	func joinRoom(
		space: String,
		room: String,
		participant: String
	) async throws(MoodhoodAPIClientError)
}
