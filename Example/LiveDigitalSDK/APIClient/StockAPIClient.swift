import Foundation


final class StockAPIClient {
	private var urlSession: URLSession = {
		var config = URLSessionConfiguration.default
		config.httpShouldSetCookies = false
		return URLSession(configuration: config)
	}()

	private let decoder = JSONDecoder()
	private let baseURL: URL

	init(baseURL: URL) {
		self.baseURL = baseURL
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
	) throws(APIClientError) -> ResponseType {
		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIClientError.noResponse
		}
		guard httpResponse.statusCode / 100 == 2 else {
			throw APIClientError.invalidResponse(httpResponse)
		}
		guard let data else {
			throw APIClientError.noResponse
		}
		do {
			return try decoder.decode(ResponseType.self, from: data)
		} catch {
			throw APIClientError.failedToParseResponse
		}
	}

	func handleEmptyResponse<ResponseType: Decodable>(
		data: Data?,
		response: URLResponse?
	) throws(APIClientError) -> ResponseType {
		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIClientError.noResponse
		}
		guard httpResponse.statusCode / 100 == 2 else {
			throw APIClientError.invalidResponse(httpResponse)
		}

		return EmptyResult() as! ResponseType
	}

	func data(for request: URLRequest) async throws(APIClientError) -> (Data, URLResponse) {
		do {
			return try await urlSession.data(for: request)
		} catch {
			throw .networkError(error)
		}
	}
}
