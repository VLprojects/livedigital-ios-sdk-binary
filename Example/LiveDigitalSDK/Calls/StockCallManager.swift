import PushKit
import Combine
import UserNotifications
import CallKit
import AVFAudio
import UIKit
import Intents


final class StockCallManager: NSObject {
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
		providerConfig.supportsVideo = true
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

// MARK: - CallManager implementation

extension StockCallManager: CallManager {
	var deviceToken: AnyPublisher<String?, Never> {
		deviceTokenSubject.eraseToAnyPublisher()
	}

	var deviceTokenCurrentValue: String? {
		deviceTokenSubject.value
	}

	func addObserver(_ observer: any CallManagerObserver) {
		observers.append(Weak(value: observer))
		for call in calls.values where call.direction == .outgoing && call.state == .connecting {
			observer.didInitiateCall(call)
		}
	}

	func removeObserver(_ observer: any CallManagerObserver) {
		observers.removeAll { $0.value === observer }
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

	func startCallManually(to roomAlias: String) {
		let callId = UUID()
		let callHandle = CXHandle(type: .generic, value: roomAlias)
		let startAction = CXStartCallAction(call: callId, handle: callHandle)
		startAction.isVideo = true
		let transaction = CXTransaction(action: startAction)
		callController.request(transaction) { error in
			if let error {
				print("CallKit start failed:", error)
			}
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
		update.remoteHandle = CXHandle(type: .generic, value: call.roomAlias)
		update.localizedCallerName = call.caller
		update.hasVideo = true
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
		print("Did receive incoming push with type \(type), payload: \(payload)")
		guard type == .voIP else {
			completion()
			return
		}
		guard let caller = payload.dictionaryPayload["caller"] as? String,
			let roomAlias = payload.dictionaryPayload["roomAlias"] as? String else {
			print("Failed to parse call object from push payload")
			completion()
			return
		}
		let call = Call(id: UUID(), caller: caller, roomAlias: roomAlias, direction: .incoming, state: .connecting)
		reportIncomingCall(call)
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
		let call = Call(
			id: action.callUUID,
			caller: action.handle.value,
			roomAlias: action.handle.value,
			direction: .outgoing,
			state: .active
		)
		calls[action.callUUID] = call
		observers.forEach { observer in
			observer.value?.didInitiateCall(call)
		}
		action.fulfill()
	}

	func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
		print("Call provider requested call answer with action \(action)")
		if var call = calls[action.callUUID] {
			call.state = .active
			calls[call.id] = call
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
		if var call = calls.removeValue(forKey: action.callUUID) {
			call.state = .ended
			observers.forEach { observer in
				observer.value?.didEndCall(call)
			}
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
		for observer in observers {
			observer.value?.didUpdateAudioSession(audioSession, active: true)
		}
	}

	func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
		print("Call provider did deactivate \(audioSession)")
		for observer in observers {
			observer.value?.didUpdateAudioSession(audioSession, active: false)
		}
	}
}
