import Foundation


protocol APIClient {
	// GET

	func get<ModelType: Decodable>(
		endpoint: String
	) async throws(APIClientError) -> ModelType

	func get<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String]
	) async throws(APIClientError) -> ModelType

	// POST

	func post<ModelType: Decodable>(
		endpoint: String
	) async throws(APIClientError) -> ModelType

	func post<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String]
	) async throws(APIClientError) -> ModelType

	func post<ModelType: Decodable>(
		endpoint: String,
		parameters: [String: Any]?
	) async throws(APIClientError) -> ModelType

	func post<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String],
		parameters: [String: Any]?
	) async throws(APIClientError) -> ModelType

	// PUT

	func put<ModelType: Decodable>(
		endpoint: String
	) async throws(APIClientError) -> ModelType

	func put<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String]
	) async throws(APIClientError) -> ModelType

	func put<ModelType: Decodable>(
		endpoint: String,
		parameters: [String: Any]?
	) async throws(APIClientError) -> ModelType

	func put<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String],
		parameters: [String: Any]?
	) async throws(APIClientError) -> ModelType

	// DELETE

	func delete<ModelType: Decodable>(
		endpoint: String
	) async throws(APIClientError) -> ModelType

	func delete<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String]
	) async throws(APIClientError) -> ModelType
}


extension APIClient {
	func get<ModelType: Decodable>(
		endpoint: String
	) async throws(APIClientError) -> ModelType {
		return try await get(endpoint: endpoint, headers: [:])
	}

	func post<ModelType: Decodable>(
		endpoint: String
	) async throws(APIClientError) -> ModelType {
		return try await post(endpoint: endpoint, headers: [:], parameters: nil)
	}

	func post<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String]
	) async throws(APIClientError) -> ModelType {
		return try await post(endpoint: endpoint, headers: headers, parameters: nil)
	}

	func post<ModelType: Decodable>(
		endpoint: String,
		parameters: [String: Any]?
	) async throws(APIClientError) -> ModelType {
		return try await post(endpoint: endpoint, headers: [:], parameters: parameters)
	}

	func put<ModelType: Decodable>(
		endpoint: String
	) async throws(APIClientError) -> ModelType {
		return try await put(endpoint: endpoint, headers: [:], parameters: nil)
	}

	func put<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String]
	) async throws(APIClientError) -> ModelType {
		return try await put(endpoint: endpoint, headers: headers, parameters: nil)
	}

	func put<ModelType: Decodable>(
		endpoint: String,
		parameters: [String: Any]?
	) async throws(APIClientError) -> ModelType {
		return try await put(endpoint: endpoint, headers: [:], parameters: parameters)
	}

	func delete<ModelType: Decodable>(
		endpoint: String
	) async throws(APIClientError) -> ModelType {
		return try await delete(endpoint: endpoint, headers: [:])
	}
}
