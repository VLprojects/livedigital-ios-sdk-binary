import Foundation
import SwiftUI
import Combine
import LiveDigitalSDK


@MainActor
final class StartScreenVM: ObservableObject {
	@Published var apnsPermissionGranted = false
	@Published var microphonePermissionGranted = false
	@Published var cameraPermissionGranted = false
	@Published var canInitiateCall = false
	@Published var presentedImage: Image?
	@Published var outgoingCallRoomAlias = "q3_5V3uwik"
	@Published var phoneNumber: String
	@Published var isSignedIn: Bool

	let notificationsVM = NotificationsVM()

	private let callManager: CallManager
	private let apnsTokenProvider: APNSTokenProvider
	private let apnsPermissionManager: PushPermissionsManager
	private let microphonePermissionManager: CaptureDevicePermissionsManager
	private let cameraPermissionManager: CaptureDevicePermissionsManager
	private let qrGenerator: QRGenerator = StockQRGenerator()

	private let accountManager: AccountManager

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
			apnsTokenProvider: apnsTokenProvider
		)

		self.isSignedIn = accountManager.isSignedIn
		self.phoneNumber = Defaults.phoneNumber ?? ""

		accountManager.isSignedInPublisher
			.receive(on: RunLoop.main)
			.assign(to: &$isSignedIn)

		bindPermissionsStates()
		bindOutgoingCallState()
		notificationsVM.show("LiveDigitalSDK version: \(LiveDigital.version())")
	}
}

// MARK: - Internal methods

internal extension StartScreenVM {
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
			if accountManager.isSignedIn {
				do {
					try await accountManager.signOut()
					self.notificationsVM.show("Successfully unregistered")
					print("Successfully unregistered")
				} catch {
					self.notificationsVM.show("Failed to unregister: \(error)")
					print("Failed to unregister: \(error)")
				}
			} else {
				do {
					let registeredDevice = try await accountManager.signIn(phone: self.phoneNumber)
					self.notificationsVM.show("Successfully registered: \(registeredDevice)")
					print("Successfully registered: \(registeredDevice)")
				} catch {
					self.notificationsVM.show("Failed to register: \(error)")
					print("Failed to register: \(error)")
				}
			}
		}
	}

	func initiateCall() {
		callManager.startCallManually(to: outgoingCallRoomAlias)
	}
}

// MARK: - Private methods

private extension StartScreenVM {
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
		Publishers.CombineLatest(
				$outgoingCallRoomAlias.map { !$0.isEmpty },
				apnsPermissionManager.permissionState.map { $0 == .allowed }
			)
			.receive(on: DispatchQueue.main)
			.map { haveRoom, havePermission in
				return haveRoom && havePermission
			}
			.assign(to: &$canInitiateCall)
	}
}
