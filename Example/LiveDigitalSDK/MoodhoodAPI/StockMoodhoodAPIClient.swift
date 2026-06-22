import Foundation


internal final class StockMoodhoodAPIClient {
	private enum Endpoints {
		static let createMoodhoodAPIToken = "/v1/auth/token"
		static func createParticipant(space: String) -> String { "/v1/spaces/\(space)/participants" }
		static func createSignalingToken(space: String, participant: String) -> String {
			"/v1/spaces/\(space)/participants/\(participant)/signaling-token"
		}
		static func fetchRoomByAlias(roomAlias: String) -> String {
			"/v1/spaces/room-by-alias/\(roomAlias)"
		}
		static func fetchRoom(space: String, room: String) -> String {
			"/v1/spaces/\(space)/rooms/\(room)"
		}
		static func joinRoom(space: String, room: String) -> String {
			"/v1/spaces/\(space)/rooms/\(room)/join"
		}
	}

	private let apiClient: APIClient
	private var userToken: MoodhoodUserToken?
	private let environment: MoodhoodAPIEnvironment

	init(environment: MoodhoodAPIEnvironment) {
		self.apiClient = StockAPIClient(baseURL: environment.apiHost)
		self.environment = environment
	}
}

extension StockMoodhoodAPIClient: MoodhoodAPIClient {
	var isAuthorized: Bool {
		return userToken != nil
	}

	@discardableResult
	func authorizeAsGuest() async throws(APIClientError) -> MoodhoodUserToken {
		let token: MoodhoodUserToken = try await apiClient.post(
			endpoint: Endpoints.createMoodhoodAPIToken,
			parameters: [
				"client_id": environment.clientId,
				"client_secret": environment.clientSecret,
				"grant_type": "client_credentials"
			]
		)
		print("Created user token: \(token)")
		self.userToken = token
		return token
	}

	func unauthorize() {
		self.userToken = nil
	}

	func createParticipant(
		space: String,
		room: String,
		clientUniqueId: String,
		role: String,
		name: String
	) async throws(APIClientError) -> MoodhoodParticipant {
		guard let userToken else {
			throw .notAuthorized
		}

		return try await apiClient.post(
			endpoint: Endpoints.createParticipant(space: space),
			headers: [
				"Authorization": "\(userToken.tokenType) \(userToken.accessToken)",
			],
			parameters: [
				"name": name,
				"roomId": room,
				"role": role,
				"clientUniqueId": clientUniqueId
			]
		)
	}

	func createSignalingToken(
		space: String,
		participant: String
	) async throws(APIClientError) -> SignalingToken {
		guard let userToken else {
			throw .notAuthorized
		}

		return try await apiClient.post(
			endpoint: Endpoints.createSignalingToken(space: space, participant: participant),
			headers: [
				"Authorization": "\(userToken.tokenType) \(userToken.accessToken)",
			]
		)
	}

	func fetchRoom(
		space: String,
		room: String
	) async throws(APIClientError) -> Room {
		guard let userToken else {
			throw .notAuthorized
		}

		return try await apiClient.get(
			endpoint: Endpoints.fetchRoom(space: space, room: room),
			headers: [
				"Authorization": "\(userToken.tokenType) \(userToken.accessToken)",
			]
		)
	}

	func fetchRoom(roomAlias: String) async throws(APIClientError) -> Room {
		guard let userToken else {
			throw .notAuthorized
		}

		return try await apiClient.get(
			endpoint: Endpoints.fetchRoomByAlias(roomAlias: roomAlias),
			headers: [
				"Authorization": "\(userToken.tokenType) \(userToken.accessToken)",
			]
		)
	}

	func joinRoom(
		space: String,
		room: String,
		participant: String
	) async throws(APIClientError) {
		guard let userToken else {
			throw .notAuthorized
		}

		let _: EmptyResult = try await apiClient.post(
			endpoint: Endpoints.joinRoom(space: space, room: room),
			headers: [
				"Authorization": "\(userToken.tokenType) \(userToken.accessToken)",
			],
			parameters: [
				"participantId": participant,
			]
		)
	}
}
