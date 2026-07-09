import Foundation
import UIKit
import LiveDigitalSDK


protocol SessionView: AnyObject {
	func setupLocalPreview(_ localPreview: UIView)
	func updateVideoButtonState(isOn: Bool)
	func updateAudioButtonState(isOn: Bool)
	func updateCanFinish(_ canFinish: Bool)
	func addPeer(_ peer: Peer)
	func removePeers(_ peers: Set<PeerId>)
	func updateVideoView(_ videoView: UIView, for peer: Peer, trackLabel: TrackLabel)
	func updateVideo(isActive: Bool, for peer: Peer, trackLabel: TrackLabel)
	func updateAudio(isActive: Bool, for peer: Peer, trackLabel: TrackLabel)
	func updatePeerAppData(_ peerId: PeerId, appData: [String : Any])
	func isVideoTrackVisible(peer: Peer, trackLabel: TrackLabel) -> Bool
	func dismiss()
}
