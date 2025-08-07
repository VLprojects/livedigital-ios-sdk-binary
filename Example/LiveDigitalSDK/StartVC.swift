import Foundation
import UIKit
import LiveDigitalSDK


final class StartVC: UIViewController {
	private struct Constants {
		static let testSpaceId = "612dbb98b2f9d4a99f18f553"
		static let testRoomId = "61554214ae218a31f78e8bc8"
	}

	@IBOutlet var spaceIdInput: UITextField!
	@IBOutlet var roomIdInput: UITextField!
	@IBOutlet var startButton: UIButton!
	@IBOutlet var versionLabel: UILabel!

	override func viewDidLoad() {
		super.viewDidLoad()
		spaceIdInput.text = Constants.testSpaceId
		roomIdInput.text = Constants.testRoomId
		versionLabel.text = "LiveDigitalSDK version: \(LiveDigital.version())"
	}

	@IBAction func startTapped() {
		performSegue(withIdentifier: "StartSession", sender: self)
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "StartSession" else {
			return
		}
		
		if let destination = segue.destination as? SessionVC {
			destination.spaceId = spaceIdInput.text
			destination.roomId = roomIdInput.text
		}
	}
}
