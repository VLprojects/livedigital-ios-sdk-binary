import Foundation


final class CurlRequestPrinter {
	func print(_ request: URLRequest) {
		Swift.print(curlString(for: request))
	}

	func curlString(for request: URLRequest) -> String {
		var parts: [String] = ["curl"]

		if let method = request.httpMethod, method != "GET" {
			parts.append("-X \(method)")
		}

		for (key, value) in request.allHTTPHeaderFields ?? [:] {
			parts.append("-H \(shellQuote("\(key): \(value)"))")
		}

		if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
			parts.append("--data \(shellQuote(bodyString))")
		}

		if let url = request.url {
			parts.append(shellQuote(url.absoluteString))
		}

		return parts.joined(separator: " \\\n  ")
	}

	private func shellQuote(_ value: String) -> String {
		"'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
	}
}
