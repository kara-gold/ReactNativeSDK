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

		// The title is an ATTRIBUTED string, which is why every colour setting was
		// ignored: setTitleColor does nothing against one, and the SDK builds it
		// with the button's own background colour, hence a label that always
		// matched the fill. Recolour the string itself, keeping its font.
		for state in [UIControl.State.normal, .highlighted] {
			guard let current = button.attributedTitle(for: state) ?? plain(state, on: button)
			else { continue }
			let recoloured = NSMutableAttributedString(attributedString: current)
			recoloured.addAttribute(
				.foregroundColor,
				value: UIColor.white,
				range: NSRange(location: 0, length: recoloured.length)
			)
			button.setAttributedTitle(recoloured, for: state)
		}
	}

	// Falls back to the plain title so the recolouring also covers the case where
	// the SDK has not built an attributed one yet.
	private func plain(_ state: UIControl.State, on button: UIButton) -> NSAttributedString? {
		guard let title = button.title(for: state), !title.isEmpty else { return nil }
		return NSAttributedString(
			string: title,
			attributes: [.font: button.titleLabel?.font ?? UIFont.systemFont(ofSize: 12)]
		)
	}
}
