import Foundation
import UIKit
import idenfyviews

//  The screen before the camera, with a file option next to the photo one.
//
//  iDenfy sends the user straight into a live camera preview, and the only way
//  to pick an existing file is a small icon inside the camera's own toolbar,
//  which reads as a camera control rather than a choice. A proof of address is
//  usually a PDF already sitting on the phone, so the file route is the common
//  case, not the fallback.
//
//  The SDK exposes no "start on the picker" setting, so the button advances the
//  flow exactly as Continue does and asks KaraIdenfyLayout to press the camera
//  screen's own upload button as soon as it appears. Both halves are public API.
//  If anything moves, the user simply lands on the camera with its upload icon
//  still there, which is today's behaviour.
@MainActor
final class KaraIdenfyDocumentOnBoardingView: StaticCameraOnBoardingViewV2 {
	private static let spacing = CGFloat(12)
	private var installed = false

	override func layoutSubviews() {
		super.layoutSubviews()
		guard !installed, bounds.width > 0 else { return }
		installed = true
		addFileButton()
	}

	private func addFileButton() {
		let title = Bundle.main.localizedString(
			forKey: "kara_choose_file", value: "", table: "Idenfy"
		)
		let anchor = idenfyUIEnabledButtonCameraOnBoardingContinue
		guard !title.isEmpty, title != "kara_choose_file", let parent = anchor.superview
		else { return }

		let button = UIButton(type: .system)
		button.setTitle(title, for: .normal)
		button.titleLabel?.font = anchor.titleLabel?.font
		button.setTitleColor(.white, for: .normal)
		// The app's grey `secondary` button, same as the retake actions.
		button.backgroundColor = UIColor(red: 38 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1)
		button.addTarget(self, action: #selector(chooseFile), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		parent.addSubview(button)

		NSLayoutConstraint.activate([
			button.leadingAnchor.constraint(equalTo: anchor.leadingAnchor),
			button.trailingAnchor.constraint(equalTo: anchor.trailingAnchor),
			button.heightAnchor.constraint(equalTo: anchor.heightAnchor),
			button.bottomAnchor.constraint(equalTo: anchor.topAnchor, constant: -Self.spacing),
		])
		// KaraIdenfyLayout rounds it with everything else on the next pass.
	}

	@objc private func chooseFile() {
		KaraIdenfyLayout.shared.opensFilePickerOnNextCamera = true
		delegate?.continueButtonPressedAction()
	}
}
