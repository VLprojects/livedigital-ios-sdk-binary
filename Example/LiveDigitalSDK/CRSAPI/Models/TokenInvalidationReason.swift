enum TokenInvalidationReason: String, Codable {
	case tokenExpired = "token_expired"
	case tokenInvalid = "token_invalid"
	case feedbackService = "feedback_service"
}
