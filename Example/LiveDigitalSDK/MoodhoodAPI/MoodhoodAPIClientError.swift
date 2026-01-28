import Foundation


enum MoodhoodAPIClientError: Error {
	case clientDeallocated
	case notAuthorized
	case failedToComposeRequest
	case networkError(Error)
	case failedToParseResponse
	case invalidResponse(HTTPURLResponse)
	case noResponse
}
