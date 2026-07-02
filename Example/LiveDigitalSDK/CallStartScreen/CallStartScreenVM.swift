import Foundation
import SwiftUI
import Combine
import LiveDigitalSDK


@MainActor
final class CallStartScreenVM: ObservableObject {
	@Published var apnsPermissionGranted = false
	@Published var authorizationInProgress = false
	@Published var microphonePermissionGranted = false
	@Published var cameraPermissionGranted = false
	@Published var canInitiateCall = false
	@Published var presentedImage: Image?
	@Published var localPhoneNumber: String
	@Published var isSignedIn: Bool
	@Published var outgoingPhoneNumber: String

	let notificationsVM = NotificationsVM()

	private let callManager: CallManager
	private let apnsTokenProvider: APNSTokenProvider
	private let apnsPermissionManager: PushPermissionsManager
	private let microphonePermissionManager: CaptureDevicePermissionsManager
	private let cameraPermissionManager: CaptureDevicePermissionsManager
	private let qrGenerator: QRGenerator = StockQRGenerator()
	private let accountManager: AccountManager
	private var cancellables = Set<AnyCancellable>()

	init(
		callManager: CallManager,
		apnsTokenProvider: APNSTokenProvider,
		apnsPermissionManager: PushPermissionsManager,
		microphonePermissionManager: CaptureDevicePermissionsManager,
		cameraPermissionManager: CaptureDevicePermissionsManager
	) {
		self.callManager = callManager
		self.apnsTokenProvider = apnsTokenProvider
		self.apnsPermissionManager = apnsPermissionManager
		self.microphonePermissionManager = microphonePermissionManager
		self.cameraPermissionManager = cameraPermissionManager

		self.accountManager = FakeAccountManager(
			callManager: callManager,
			apnsTokenProvider: apnsTokenProvider
		)

		self.isSignedIn = accountManager.isSignedIn
		self.localPhoneNumber = Defaults.localPhoneNumber ?? ""
		self.outgoingPhoneNumber = Defaults.outgoingPhoneNumber ?? ""

		accountManager.isSignedInPublisher
			.receive(on: RunLoop.main)
			.assign(to: &$isSignedIn)

		bindPermissionsStates()
		bindOutgoingCallState()
		notificationsVM.show("LiveDigitalSDK version: \(LiveDigital.version())")

		applyInitialStateOnCRS()
	}
}

// MARK: - Internal methods

internal extension CallStartScreenVM {
	var canInitiateOutgoingCall: Bool {
		canInitiateCall && !strippedOutgoingPhoneNumber.isEmpty
	}

	func requestApnsPermission() {
		apnsPermissionManager.requestPermission()
	}

	func requestCameraPermission() {
		cameraPermissionManager.requestPermission()
	}

	func requestMicrophonePermission() {
		microphonePermissionManager.requestPermission()
	}

	func copyAPNSToken() {
		UIPasteboard.general.string = apnsTokenProvider.deviceTokenCurrentValue
		UINotificationFeedbackGenerator().notificationOccurred(.success)
		notificationsVM.show(String(localized: .apnsTokenCopiedNotification))
	}

	func presentAPNSToken() {
		guard let tokenString = apnsTokenProvider.deviceTokenCurrentValue else {
			return
		}
		presentedImage = qrGenerator.generate(from: tokenString)
	}

	func toggleAuthorization() {
		Task { @MainActor in
			await accountManager.isSignedIn ? signOut() : signIn()
		}
	}

	func initiateCall() {
		Defaults.outgoingPhoneNumber = outgoingPhoneNumber
		callManager.startCallManually(to: strippedOutgoingPhoneNumber)
	}
}

// MARK: - Private methods

private extension CallStartScreenVM {
	var strippedPhoneNumber: String {
		localPhoneNumber.filter { $0.isNumber || $0 == "+" }
	}

	var strippedOutgoingPhoneNumber: String {
		outgoingPhoneNumber.filter { $0.isNumber || $0 == "+" }
	}

	func signIn() async {
		authorizationInProgress = true
		do {
			let registeredDevice = try await accountManager.signIn(phone: self.strippedPhoneNumber)
			notificationsVM.show("Successfully registered: \(registeredDevice)")
			print("Successfully registered: \(registeredDevice)")
		} catch {
			notificationsVM.show("Failed to register: \(error)")
			print("Failed to register: \(error)")
		}
		authorizationInProgress = false
	}

	func signOut() async {
		authorizationInProgress = true
		do {
			try await accountManager.signOut()
			notificationsVM.show("Successfully unregistered")
			print("Successfully unregistered")
		} catch {
			notificationsVM.show("Failed to unregister: \(error)")
			print("Failed to unregister: \(error)")
		}
		authorizationInProgress = false
	}

	func bindPermissionsStates() {
		apnsPermissionManager.permissionState
			.map { $0 == .allowed }
			.receive(on: DispatchQueue.main)
			.assign(to: &$apnsPermissionGranted)

		cameraPermissionManager.permissionState
			.map { $0 == .allowed }
			.receive(on: DispatchQueue.main)
			.assign(to: &$cameraPermissionGranted)

		microphonePermissionManager.permissionState
			.map { $0 == .allowed }
			.receive(on: DispatchQueue.main)
			.assign(to: &$microphonePermissionGranted)
	}

	func bindOutgoingCallState() {
		apnsPermissionManager.permissionState
			.map { $0 == .allowed }
			.receive(on: DispatchQueue.main)
			.assign(to: &$canInitiateCall)
	}

	/// Refresh APNS token in CRS on app start.
	func applyInitialStateOnCRS() {
		apnsPermissionManager.permissionState
			.first { $0 != .unknown }
			.sink { [weak self] state in
				guard let self else {
					return
				}
				if state == .allowed, self.accountManager.isSignedIn {
					Task { @MainActor in
						await self.signIn()
					}
				}
			}
			.store(in: &cancellables)
	}
}
