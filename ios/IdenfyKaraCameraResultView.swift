import Foundation
import UIKit
import idenfyviews

//  The capture result screen, with a borderless grey retake button.
//
//  On this screen the SDK paints the retake label with the button's BORDER
//  colour and ignores `...RetakePhotoButtonTextColor` entirely. Setting the
//  border equal to the fill is what made the label vanish through seven
//  attempts: grey on grey, then white on white.
//
//  So the two are split: the theme keeps a cream border colour, which is what
//  makes the label cream, and the border WIDTH is zeroed here so nothing is
//  actually drawn. The result is the app's plain grey `secondary` button.
//
//  No initialiser is declared on purpose. Adding one makes Swift demand
//  init(coder:) as well, and the SDK deep-copies injected views through
//  NSKeyedArchiver: an unavailable init(coder:) crashed the app on capture.
@MainActor
final class KaraIdenfyCameraResultView: CameraResultViewV2 {
	override func layoutSubviews() {
		super.layoutSubviews()
		// Re-applied every pass: the SDK restyles the button after its own layout.
		let button = chooseAnotherFileButton
		button.layer.borderWidth = 0

		// The label is gold whatever the settings say, so it is recoloured on the
		// string itself. This works now only because the label is actually there:
		// the earlier attempts recoloured a title that was invisible for another
		// reason, which is why they all looked like no-ops.
		if let title = button.attributedTitle(for: .normal), title.length > 0 {
			let cream = NSMutableAttributedString(attributedString: title)
			cream.addAttribute(
				.foregroundColor,
				value: KaraIdenfyTheme.text,
				range: NSRange(location: 0, length: cream.length)
			)
			button.setAttributedTitle(cream, for: .normal)
			button.setAttributedTitle(cream, for: .highlighted)
		}
		button.setTitleColor(KaraIdenfyTheme.text, for: .normal)
		button.setTitleColor(KaraIdenfyTheme.text, for: .highlighted)
		button.titleLabel?.textColor = KaraIdenfyTheme.text
	}
}
