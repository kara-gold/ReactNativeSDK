import Foundation
import UIKit
import idenfyviews

//  The capture result screen, with a readable retake button.
//
//  `idenfyPhotoResultViewRetakePhotoButtonTextColor` has no effect here:
//  measured 2026-07-31, the SDK paints the title with the button's own
//  BACKGROUND colour, so the label was invisible whatever the setting. A gold
//  fill gave gold text, a white fill gave white text. Six attempts through the
//  settings API were doomed for that reason, and the colour is set on the
//  button itself instead.
//
//  No initialiser is declared on purpose: adding one makes Swift demand
//  init(coder:) as well, and the SDK deep-copies injected views through
//  NSKeyedArchiver. An unavailable init(coder:) crashed the app the moment a
//  photo was taken, the same archiving path that took the process down on
//  2026-07-30. With none declared, the superclass's are inherited untouched.
@MainActor
final class KaraIdenfyCameraResultView: CameraResultViewV2 {
	// The app's grey `secondary` button, which is what was asked for originally.
	private static let fill = UIColor(red: 38 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1)

	override func layoutSubviews() {
		super.layoutSubviews()
		// Re-applied on every pass: the SDK rewrites the title colour whenever it
		// restyles the button, so setting it once is not enough.
		let button = chooseAnotherFileButton
		button.backgroundColor = Self.fill
		button.layer.borderColor = Self.fill.cgColor

		// The title is set here, text included, not just its colour. Recolouring
		// alone never showed anything, and the fill obeys in the same method, so
		// the button simply carries no title on this screen. The string is the
		// SDK's own, so it stays translated in the four locales.
		let title = Bundle.main.localizedString(
			forKey: "idenfy_document_and_face_camera_results_button_retake_photo_title_v2",
			value: "",
			table: "Idenfy"
		)
		guard !title.hasPrefix("idenfy_"), !title.isEmpty else { return }

		let styled = NSAttributedString(
			string: title,
			attributes: [
				.foregroundColor: UIColor.white,
				.font: button.titleLabel?.font ?? UIFont.boldSystemFont(ofSize: 12),
			]
		)
		button.setAttributedTitle(styled, for: .normal)
		button.setAttributedTitle(styled, for: .highlighted)
	}
}
