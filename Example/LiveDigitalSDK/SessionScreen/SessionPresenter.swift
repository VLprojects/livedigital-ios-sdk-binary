import Foundation
import LiveDigitalSDK


protocol SessionPresenter: AnyObject {
	var availableAudioRoutes: [AudioRoute] { get }
	var currentAudioRoute: AudioRoute { get }

	func viewDidLoad()
	func updateLocalVideoEnabled(_ enabled: Bool)
	func updateLocalAudioEnabled(_ enabled: Bool)
	func updatePreferred(route: AudioRoute)
	func updateVideoTrackVisible(peerId: PeerId, trackLabel: TrackLabel, isVisible: Bool)
	func flipCamera()
	func finishSession()
}
