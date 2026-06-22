import Foundation


enum APIClientError: Error {
	case clientDeallocated
	case notAuthorized
	case failedToComposeRequest
	case networkError(Error)
	case failedToParseResponse(Data)
	case invalidResponse(HTTPURLResponse, Data?)
	case noResponse
}


extension APIClientError: CustomDebugStringConvertible {
	var debugDescription: String {
		switch self {
			case .clientDeallocated:
				"APIClientError.clientDeallocated"
			case .notAuthorized:
				"APIClientError.notAuthorized"
			case .failedToComposeRequest:
				"APIClientError.failedToComposeRequest"
			case .networkError(let error):
				"APIClientError.networkError(\(error))"
			case .failedToParseResponse(let data):
				if let dataString = String(data: data, encoding: .utf8) {
					"APIClientError.failedToParseResponse(\(dataString))"
				} else {
					"APIClientError.failedToParseResponse"
				}
			case .invalidResponse(let httpURLResponse, let data):
				if let data, let dataString = String(data: data, encoding: .utf8) {
					"APIClientError.invalidResponse(\(httpURLResponse): \(dataString))"
				} else {
					"APIClientError.invalidResponse(\(httpURLResponse))"
				}
			case .noResponse:
				"APIClientError.noResponse"
		}
	}
}
