import Foundation
import JWTKit


struct OutboundCallTokenPayload: JWTPayload {
	struct OutboundCallData: Codable {
		let direction: String
		let callee: String
		let tenantId: String
		let caller: String
	}

	let iss: IssuerClaim
	let sub: SubjectClaim
	let aud: AudienceClaim
	let exp: ExpirationClaim
	let iat: IssuedAtClaim
	let jti: IDClaim

	let channelId: String
	let groups: [String]
	let producePermissions: [String]
	let externalCall: OutboundCallData

	func verify(using algorithm: some JWTAlgorithm) async throws {
		try exp.verifyNotExpired()
	}
}
