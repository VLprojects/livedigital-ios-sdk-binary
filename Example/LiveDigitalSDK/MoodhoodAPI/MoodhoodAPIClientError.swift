import Foundation


enum MoodhoodAPIClientError: Error {
	case clientDeallocated
	case failedToComposeRequest
	case networkError(Error)
	case failedToParseResponse
	case invalidResponse(HTTPURLResponse)
	case noResponse
}
