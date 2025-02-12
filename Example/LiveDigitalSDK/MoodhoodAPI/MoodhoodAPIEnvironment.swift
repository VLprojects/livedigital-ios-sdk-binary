import Foundation


struct MoodhoodAPIEnvironment {
	let apiHost: URL
	let clientId: String
	let clientSecret: String

	public init(apiHost: URL, clientId: String, clientSecret: String) {
		self.apiHost = apiHost
		self.clientId = clientId
		self.clientSecret = clientSecret
	}
}
