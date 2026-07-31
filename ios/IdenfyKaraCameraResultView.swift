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
//  So the two are split: the theme keeps a white border colour, which is what
//  makes the label white, and the border WIDTH is zeroed here so nothing is
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
		chooseAnotherFileButton.layer.borderWidth = 0
	}
}
