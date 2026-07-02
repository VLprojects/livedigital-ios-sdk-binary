import PushKit
import Combine
import UserNotifications
import CallKit
import AVFAudio
import UIKit
import Intents
import LiveDigitalSDK
import JWTKit


final class StockCallManager: NSObject {
	var localPhone: String?

	private let permissionStateSubject = CurrentValueSubject<PermissionState, Never>(.unknown)
	private var deviceTokenSubject = CurrentValueSubject<String?, Never>(nil)
	private let notificationCenter = UNUserNotificationCenter.current()
	private let pushRegistry: PKPushRegistry
	private let callProvider: CXProvider
	private let callController: CXCallController
	private var observers = [Weak<any CallManagerObserver>]()
	private var calls = [UUID: Call]()

	override init() {
		let providerConfig = CXProviderConfiguration()
		providerConfig.includesCallsInRecents = true
		providerConfig.supportsVideo = false
		providerConfig.maximumCallsPerCallGroup = 1
		providerConfig.supportedHandleTypes = [.generic]
		self.callProvider = CXProvider(configuration: providerConfig)

		self.callController = CXCallController()

		let registry = PKPushRegistry(queue: .main)
		registry.desiredPushTypes = [.voIP]
		self.pushRegistry = registry

		super.init()

		callProvider.setDelegate(self, queue: .main)
		registry.delegate = self

		if let token = registry.pushToken(for: .voIP) {
			deviceTokenSubject.send(tokenString(for: token))
		}

		refreshAuthorizationStatus()
	}

	deinit {
		callProvider.invalidate()
	}
}

// MARK: - PushPermissionsManager implementation

extension StockCallManager: PushPermissionsManager {
	var permissionState: AnyPublisher<PermissionState, Never> {
		permissionStateSubject.eraseToAnyPublisher()
	}

	var permissionStateCurrentValue: PermissionState {
		permissionStateSubject.value
	}

	func requestPermission() {
		notificationCenter.requestAuthorization(options: [.badge, .alert, .sound], completionHandler: { [weak self] (_, error) in
			if let error {
				print("Failed to request APNS permission: \(error)")
			}
			self?.refreshAuthorizationStatus()
		})
	}
}

// MARK: - APNSTokenProvider implementation

extension StockCallManager: APNSTokenProvider {
	var deviceToken: AnyPublisher<String?, Never> {
		deviceTokenSubject.eraseToAnyPublisher()
	}

	var deviceTokenCurrentValue: String? {
		deviceTokenSubject.value
	}
}

// MARK: - CallManager implementation

extension StockCallManager: CallManager {
	func addObserver(_ observer: any CallManagerObserver) {
		observers.append(Weak(value: observer))
		for call in calls.values where call.direction == .outgoing && call.state == .connecting {
			observer.didInitiateCall(call)
		}
	}

	func removeObserver(_ observer: any CallManagerObserver) {
		observers.removeAll { $0.value === observer }
	}

	func toggleMicrophone(muted: Bool, in call: Call) {
		let muteAction = CXSetMutedCallAction(call: call.id, muted: muted)
		let transaction = CXTransaction(action: muteAction)
		callController.request(transaction) { error in
			if let error {
				print("CallKit failed to toggle mute state:", error)
			}
		}
	}

	func startCallFromIntent(_ intent: INIntent) {
		// Even on modern iOS versions we receive deprecated intents when user taps a record in recent calls,
		// so we have to handle deprecated INStartVideoCallIntent / INStartAudioCallIntent.
		guard let contact: INPerson = (intent as? INStartCallIntent)?.contacts?.first ??
			(intent as? INStartVideoCallIntent)?.contacts?.first ??
			(intent as? INStartAudioCallIntent)?.contacts?.first else {
			return
		}
		guard let handle = contact.personHandle?.value else {
			return
		}
		startCallManually(to: handle)
	}

	func startCallManually(to operatorNumber: String) {
		let callId = UUID()
		let callHandle = CXHandle(type: .phoneNumber, value: operatorNumber)
		let startAction = CXStartCallAction(call: callId, handle: callHandle)
		startAction.isVideo = false
		let transaction = CXTransaction(action: startAction)
		callController.request(transaction) { error in
			if let error {
				print("CallKit start failed:", error)
			}
		}
	}

	func endCall(_ call: Call) {
		reportCallEnded(call)
		observers.forEach { observer in
			observer.value?.didEndCall(call)
		}
	}

	func endCall(_ callId: UUID) {
		guard let call = calls[callId] else {
			return
		}
		reportCallEnded(call)
		observers.forEach { observer in
			observer.value?.didEndCall(call)
		}
	}

	func reportCallFailed(_ call: Call) {
		callProvider.reportCall(with: call.id, endedAt: nil, reason: .failed)
		calls.removeValue(forKey: call.id)
	}

	func reportCallEnded(_ call: Call) {
		callProvider.reportCall(with: call.id, endedAt: nil, reason: .remoteEnded)
		calls.removeValue(forKey: call.id)
	}

	func reportCallAnsweredOnOtherDevice(_ call: Call) {
		callProvider.reportCall(with: call.id, endedAt: nil, reason: .answeredElsewhere)
		calls.removeValue(forKey: call.id)
	}

	func reportCallDeclined(_ call: Call) {
		callProvider.reportCall(with: call.id, endedAt: nil, reason: .declinedElsewhere)
		calls.removeValue(forKey: call.id)
	}
}

// MARK: - Private methods

private extension StockCallManager {
	func refreshAuthorizationStatus() {
		notificationCenter.getNotificationSettings { [weak self] settings in
			let state: PermissionState = switch settings.authorizationStatus {
				case .authorized, .provisional, .ephemeral: .allowed
				case .denied: .disabled
				case .notDetermined: .undecided
				@unknown default: .unknown
			}
			DispatchQueue.main.async { [weak self] in
				self?.permissionStateSubject.send(state)
			}
		}
	}

	func tokenString(for tokenData: Data) -> String {
		return tokenData.reduce("") { $0 + String(format: "%02x", $1) }
	}

	func reportIncomingCall(_ call: Call) {
		let update = CXCallUpdate()
		update.remoteHandle = CXHandle(type: .generic, value: call.caller)
		update.localizedCallerName = call.caller
		update.hasVideo = false
		update.supportsHolding = false
		update.supportsDTMF = false
		update.supportsGrouping = false
		update.supportsUngrouping = false

		calls[call.id] = call
		print("Reporting incoming call \(call)")
		callProvider.reportNewIncomingCall(with: call.id, update: update, completion: { [weak self] error in
			if let error {
				self?.calls.removeValue(forKey: call.id)
				print("Error reporting call: \(error)")
			} else {
				print("Successfully reported incoming call \(call)")
			}
		})
	}

	func notifyCallFinished(_ call: Call) {
		let endedCall = call.withState(.ended)
		observers.forEach { observer in
			observer.value?.didEndCall(endedCall)
		}
	}

	func notifyCallDeclined(_ call: Call) {
		let endedCall = call.withState(.ended)
		observers.forEach { observer in
			observer.value?.didDeclineCall(endedCall)
		}
	}

	func notifyCallAnswered(_ call: Call) {
		let answeredCall = call.withState(.connecting)
		observers.forEach { observer in
			observer.value?.callWasAnswered(answeredCall)
		}
	}

	func handleCallPush(callId: UUID, action: CallPushAction, payload: [AnyHashable: Any]) {
		guard let localPhone else {
			print("No local phone number set")
			return
		}

		switch action {
			case .start:
				guard let caller = payload["caller"] as? String,
					let signalingToken = payload["signalingToken"] as? String else {
					print("Failed to parse call object from push payload")
					return
				}
				let call = Call(
					id: callId,
					caller: caller,
					callee: localPhone,
					signalingToken: signalingToken,
					direction: .incoming,
					state: .new
				)
				reportIncomingCall(call)

			case .end:
				handleCallEnd(callId, reason: .remoteEnded, payload: payload)

			case .answered:
				handleCallEnd(callId, reason: .answeredElsewhere, payload: payload)

			case .cancelled:
				handleCallEnd(callId, reason: .remoteEnded, payload: payload)

			case .declinedByCallee:
				handleCallEnd(callId, reason: .declinedElsewhere, payload: payload)
		}
	}

	func handleCallEnd(_ callId: UUID, reason: CXCallEndedReason, payload: [AnyHashable: Any]) {
		print("Call \(callId) ended, details: \(payload)")
		callProvider.reportCall(with: callId, endedAt: .now, reason: reason)
		if let call = calls.removeValue(forKey: callId) {
			notifyCallFinished(call)
		} else {
			print("Call \(callId) not found locally")
		}
	}

	/// This method is implemented only for demonstration without actual app specific backend.
	/// In real world implementation token must be generated on server side.
	func makeOutboundCallToken(
		callerPhoneNumber: String,
		calleePhoneNumber: String,
	) async throws -> String {
		let keys = JWTKeyCollection()

		let formatedSecret = AppConfig.crsAPIKey
		let components = formatedSecret.split(separator: ":")
		let tenantId = String(components[0])
		let secret = AppConfig.signalingTokenSecret

		await keys.add(hmac: HMACKey(from: Data(secret.utf8)), digestAlgorithm: .sha256)

		let payload = OutboundCallTokenPayload(
			iss: IssuerClaim(value: tenantId),
			sub: SubjectClaim(value: DeviceEnvironmentProvider.environment.deviceId),
			aud: AudienceClaim(value: ["host"]),
			exp: ExpirationClaim(value: .now.addingTimeInterval(86400)),
			iat: IssuedAtClaim(value: .now.addingTimeInterval(-600)),
			jti: IDClaim(value: UUID().uuidString.lowercased()),
			channelId: callerPhoneNumber,
			groups: ["user"],
			producePermissions: ["microphone"],
			externalCall: OutboundCallTokenPayload.OutboundCallData(
				direction: "outbound",
				callee: calleePhoneNumber,
				tenantId: tenantId,
				caller: callerPhoneNumber
			)
		)

		return try await keys.sign(payload)
	}
}

// MARK: - PKPushRegistryDelegate implementation

extension StockCallManager: PKPushRegistryDelegate {
	func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
		guard type == .voIP else {
			return
		}
		deviceTokenSubject.send(tokenString(for: pushCredentials.token))
	}

	func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
		guard type == .voIP else {
			return
		}
		deviceTokenSubject.send(nil)
	}

	func pushRegistry(
		_ registry: PKPushRegistry,
		didReceiveIncomingPushWith payload: PKPushPayload,
		for type: PKPushType,
		completion: @escaping () -> Void
	) {
		print("Did receive incoming push with type \(type), payload: \(payload.dictionaryPayload)")
		guard type == .voIP else {
			print("Failed to handle push: invalid push type: \(type.rawValue)")
			completion()
			return
		}
		guard let actionString = payload.dictionaryPayload["kind"] as? String,
			let action = CallPushAction(rawValue: actionString) else {
			print("Failed to parse call object from push payload: no action")
			completion()
			return
		}
		guard let callIdString = payload.dictionaryPayload["sessionId"] as? String,
			let callId = UUID(uuidString: callIdString) else {
			print("Failed to parse call object from push payload: no callId")
			completion()
			return
		}
		handleCallPush(callId: callId, action: action, payload: payload.dictionaryPayload)
		completion()
	}
}

// MARK: - CXProviderDelegate implementation

extension StockCallManager: CXProviderDelegate {
	func providerDidReset(_ provider: CXProvider) {
		for call in calls.values {
			observers
				.forEach { observer in
					observer.value?.didEndCall(call)
				}
		}
		calls.removeAll()
	}

	func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
		print("Call provider requested call start with action \(action)")

		guard let localPhone else {
			print("No local phone number set")
			return
		}

		Task { @MainActor in
			do {
				let signalingToken = try await makeOutboundCallToken(
					callerPhoneNumber: localPhone,
					calleePhoneNumber: action.handle.value
				)
				print("Generated signaling token: \(signalingToken)")
				let call = Call(
					id: action.callUUID,
					caller: localPhone,
					callee: action.handle.value,
					signalingToken: signalingToken,
					direction: .outgoing,
					state: .new
				)
				calls[action.callUUID] = call
				StockLiveDigitalEngine.callAudioCoordinator.prepareSession()
				observers.forEach { observer in
					observer.value?.didInitiateCall(call)
				}
				action.fulfill()
			} catch {
				print("Failed to serialize JWT token: \(error)")
				action.fail()
				return
			}
		}
	}

	func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
		print("Call provider requested call answer with action \(action)")

		StockLiveDigitalEngine.callAudioCoordinator.prepareSession()

		if let call = calls[action.callUUID] {
			let activeCall = call.withState(.active)
			calls[call.id] = activeCall
			self.observers.forEach { observer in
				observer.value?.didReceiveCall(call)
			}
			action.fulfill()
		} else {
			action.fail()
		}
	}

	func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
		print("Call provider requested call end with action \(action)")
		if let call = calls.removeValue(forKey: action.callUUID) {
			if call.direction == .incoming, call.state == .new  {
				notifyCallDeclined(call)
			}

			notifyCallFinished(call)
			action.fulfill()
		} else {
			action.fail()
		}
	}

	func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
		print("Call provider requested to set call mute state to \(action.isMuted) with action \(action)")
		if var call = calls[action.callUUID] {
			call.isMuted = action.isMuted
			calls[call.id] = call
			for observer in observers {
				observer.value?.didUpdateCallMuteState(call)
			}
			action.fulfill()
		} else {
			action.fail()
		}
	}

	func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
		print("Call provider timed out performing action \(action)")
	}

	func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
		print("Call provider did activate \(audioSession)")

		StockLiveDigitalEngine.callAudioCoordinator.callKitDidActivate(audioSession)

		for observer in observers {
			observer.value?.didUpdateAudioSession(audioSession, active: true)
		}
	}

	func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
		print("Call provider did deactivate \(audioSession)")

		StockLiveDigitalEngine.callAudioCoordinator.callKitDidDeactivate(audioSession)

		for observer in observers {
			observer.value?.didUpdateAudioSession(audioSession, active: false)
		}
	}
}
