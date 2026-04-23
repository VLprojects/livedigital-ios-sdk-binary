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
	@Published var outgoingCallRoomAlias = "q3_5V3uwik"
	let notificationsVM = NotificationsVM()

	private let callManager: CallManager
	private let apnsPermissionManager: PushPermissionsManager
	private let microphonePermissionManager: CaptureDevicePermissionsManager
	private let cameraPermissionManager: CaptureDevicePermissionsManager

	init(
		callManager: CallManager,
		apnsPermissionManager: PushPermissionsManager,
		microphonePermissionManager: CaptureDevicePermissionsManager,
		cameraPermissionManager: CaptureDevicePermissionsManager
	) {
		self.callManager = callManager
		self.apnsPermissionManager = apnsPermissionManager
		self.microphonePermissionManager = microphonePermissionManager
		self.cameraPermissionManager = cameraPermissionManager

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
		UIPasteboard.general.string = callManager.deviceTokenCurrentValue
		UINotificationFeedbackGenerator().notificationOccurred(.success)
		notificationsVM.show(String(localized: .apnsTokenCopiedNotification))
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
