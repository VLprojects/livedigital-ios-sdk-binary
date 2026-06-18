import Foundation


final class StockAPIClient {
	private var urlSession: URLSession = {
		var config = URLSessionConfiguration.default
		config.httpShouldSetCookies = false
		return URLSession(configuration: config)
	}()

	private let decoder = JSONDecoder()
	private let curlPrinter = CurlRequestPrinter()
	private let baseURL: URL

	init(baseURL: URL) {
		self.baseURL = baseURL

		decoder.dateDecodingStrategy = .custom({ decoder in
			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [
				.withInternetDateTime,
				.withFractionalSeconds
			]
			let container = try decoder.singleValueContainer()
			let string = try container.decode(String.self)
			guard let date = formatter.date(from: string) else {
				throw DecodingError.dataCorruptedError(
					in: container,
					debugDescription: "Invalid date: \(string)"
				)
			}
			return date
		})
	}
}

// MARK: - APIClient implementation

extension StockAPIClient: APIClient {
	func post<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String],
		parameters: [String: Any]?
	) async throws(APIClientError) -> ModelType {
		try await request(endpoint: endpoint, method: "POST", headers: headers, parameters: parameters)
	}

	func get<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String]
	) async throws(APIClientError) -> ModelType {
		try await request(endpoint: endpoint, method: "GET", headers: headers)
	}

	func put<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String],
		parameters: [String: Any]?
	) async throws(APIClientError) -> ModelType {
		try await request(endpoint: endpoint, method: "PUT", headers: headers, parameters: parameters)
	}

	func delete<ModelType: Decodable>(
		endpoint: String,
		headers: [String: String]
	) async throws(APIClientError) -> ModelType {
		try await request(endpoint: endpoint, method: "DELETE", headers: headers)
	}
}

// MARK: - Private methods

private extension StockAPIClient {
	func request<ModelType: Decodable>(
		endpoint: String,
		method: String,
		headers: [String: String] = [:],
		parameters: [String: Any]? = nil
	) async throws(APIClientError) -> ModelType {
		guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
			throw APIClientError.failedToComposeRequest
		}
		components.path += endpoint
		guard let requestURL = components.url else {
			throw APIClientError.failedToComposeRequest
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

		curlPrinter.print(request)

		let (data, response) = try await data(for: request)
		return try handleResponse(data: data, response: response)
	}

	func handleResponse<ResponseType: Decodable>(
		data: Data?,
		response: URLResponse?
	) throws(APIClientError) -> ResponseType {
		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIClientError.noResponse
		}
		guard httpResponse.statusCode / 100 == 2 else {
			throw APIClientError.invalidResponse(httpResponse, data)
		}
		guard let data else {
			throw APIClientError.noResponse
		}
		do {
			if ResponseType.self == EmptyResult.self {
				if let emptyResult = EmptyResult() as? ResponseType {
					return emptyResult
				} else {
					throw APIClientError.failedToParseResponse(data)
				}
			} else {
				return try decoder.decode(ResponseType.self, from: data)
			}
		} catch {
			throw APIClientError.failedToParseResponse(data)
		}
	}

	func data(for request: URLRequest) async throws(APIClientError) -> (Data, URLResponse) {
		do {
			return try await urlSession.data(for: request)
		} catch {
			throw .networkError(error)
		}
	}
}
