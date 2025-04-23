import Foundation


internal final class StockMoodhoodAPIClient {
	private enum Endpoints {
		static let createMoodhoodAPIToken = "/v1/auth/token"
		static func createParticipant(space: String) -> String { "/v1/spaces/\(space)/participants" }
		static func createSignalingToken(space: String, participant: String) -> String {
			"/v1/spaces/\(space)/participants/\(participant)/signaling-token"
		}
		static func fetchRoom(space: String, room: String) -> String {
			"/v1/spaces/\(space)/rooms/\(room)"
		}
		static func joinRoom(space: String, room: String) -> String {
			"/v1/spaces/\(space)/rooms/\(room)/join"
		}
	}

	private static var urlSession: URLSession = {
		var config = URLSessionConfiguration.default
		config.httpShouldSetCookies = false
		return URLSession(configuration: config)
	}()

	private let environment: MoodhoodAPIEnvironment
	private let decoder = JSONDecoder()

	init(environment: MoodhoodAPIEnvironment) {
		self.environment = environment
	}
}

extension StockMoodhoodAPIClient: MoodhoodAPIClient {
	func authorizeAsGuest() async throws(MoodhoodAPIClientError) -> MoodhoodUserToken {
		return try await post(
			endpoint: Endpoints.createMoodhoodAPIToken,
			parameters: [
				"client_id": environment.clientId,
				"client_secret": environment.clientSecret,
				"grant_type": "client_credentials"
			]
		)
	}

	func createParticipant(
		userToken: MoodhoodUserToken,
		space: String,
		room: String,
		clientUniqueId: String,
		role: String,
		name: String
	) async throws(MoodhoodAPIClientError) -> MoodhoodParticipant {
		return try await post(
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
		userToken: MoodhoodUserToken,
		space: String,
		participant: String
	) async throws(MoodhoodAPIClientError) -> SignalingToken {
		return try await post(
			endpoint: Endpoints.createSignalingToken(space: space, participant: participant),
			headers: [
				"Authorization": "\(userToken.tokenType) \(userToken.accessToken)",
			]
		)
	}

	func fetchRoom(
		userToken: MoodhoodUserToken,
		space: String,
		room: String
	) async throws(MoodhoodAPIClientError) -> Room {
		return try await get(
			endpoint: Endpoints.fetchRoom(space: space, room: room),
			headers: [
				"Authorization": "\(userToken.tokenType) \(userToken.accessToken)",
			]
		)
	}

	func joinRoom(
		userToken: MoodhoodUserToken,
		space: String,
		room: String,
		participant: String
	) async throws(MoodhoodAPIClientError) {
		let _: EmptyResult = try await post(
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

// MARK: - Private methods

private extension StockMoodhoodAPIClient {
	func data(for request: URLRequest) async throws(MoodhoodAPIClientError) -> (Data, URLResponse) {
		do {
			return try await Self.urlSession.data(for: request)
		} catch {
			throw .networkError(error)
		}
	}

	private func post<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String] = [:],
		parameters: [String: Any]? = nil
	) async throws(MoodhoodAPIClientError) -> ModelType {
		try await request(endpoint: endpoint, method: "POST", headers: headers, parameters: parameters)
	}

	private func get<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String] = [:]
	) async throws(MoodhoodAPIClientError) -> ModelType {
		try await request(endpoint: endpoint, method: "GET", headers: headers)
	}

	private func request<ModelType: Decodable>(
		endpoint: String,
		method: String,
		headers: [String: String] = [:],
		parameters: [String: Any]? = nil
	) async throws(MoodhoodAPIClientError) -> ModelType {
		guard var components = URLComponents(url: environment.apiHost, resolvingAgainstBaseURL: false) else {
			throw MoodhoodAPIClientError.failedToComposeRequest
		}
		components.path += endpoint
		guard let requestURL = components.url else {
			throw MoodhoodAPIClientError.failedToComposeRequest
		}
		var request = URLRequest(url: requestURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
		request.httpMethod = method
		if let parameters {
			request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
		}
		for (key, value) in headers {
			request.setValue(value, forHTTPHeaderField: key)
		}
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		print("Sending request: \(method) \(requestURL), headers: \(request.allHTTPHeaderFields ?? [:]), body: \(parameters ?? [:])")

		let (data, response) = try await data(for: request)
		if ModelType.self == EmptyResult.self {
			return try handleEmptyResponse(data: data, response: response)
		} else {
			return try handleResponse(data: data, response: response)
		}
	}

	func handleResponse<ResponseType: Decodable>(
		data: Data?,
		response: URLResponse?
	) throws(MoodhoodAPIClientError) -> ResponseType {
		guard let httpResponse = response as? HTTPURLResponse else {
			throw MoodhoodAPIClientError.noResponse
		}
		guard httpResponse.statusCode / 100 == 2 else {
			throw MoodhoodAPIClientError.invalidResponse(httpResponse)
		}
		guard let data else {
			throw MoodhoodAPIClientError.noResponse
		}
		do {
			return try decoder.decode(ResponseType.self, from: data)
		} catch {
			throw MoodhoodAPIClientError.failedToParseResponse
		}
	}

	func handleEmptyResponse<ResponseType: Decodable>(
		data: Data?,
		response: URLResponse?
	) throws(MoodhoodAPIClientError) -> ResponseType {
		guard let httpResponse = response as? HTTPURLResponse else {
			throw MoodhoodAPIClientError.noResponse
		}
		guard httpResponse.statusCode / 100 == 2 else {
			throw MoodhoodAPIClientError.invalidResponse(httpResponse)
		}

		return EmptyResult() as! ResponseType
	}
}
