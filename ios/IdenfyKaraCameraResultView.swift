import Foundation
import UIKit
import idenfyviews

//  The capture result screen, with a readable retake button.
//
//  `idenfyPhotoResultViewRetakePhotoButtonTextColor` has no effect on this
//  screen: measured 2026-07-31, the SDK paints the title with the button's own
//  BACKGROUND colour, so the label is always invisible whatever the setting.
//  Gold fill gave gold text, white fill gave white text. Six attempts through
//  the settings API were doomed for that reason.
//
//  So the colour is set here instead, on the public button, after the SDK is
//  done with it. Injected through withCameraWithRectangleResultView.
@MainActor
final class KaraIdenfyCameraResultView: CameraResultViewV2 {
	// The superclass has no plain init: it needs to know which camera framing the
	// screen belongs to, so both variants are built explicitly below.
	required init(frame: CGRect, withRectangle: IdenfyCameraViewType) {
		super.init(frame: frame, withRectangle: withRectangle)
	}

	@available(*, unavailable)
	required convenience init?(coder: NSCoder) {
		fatalError("not used")
	}

	// The app's grey `secondary` button, which is what was asked for originally.
	private static let fill = UIColor(red: 38 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1)

	override func layoutSubviews() {
		super.layoutSubviews()
		// Re-applied on every pass: the SDK rewrites the title colour whenever it
		// re-styles the button, so setting it once is not enough.
		chooseAnotherFileButton.setTitleColor(.white, for: .normal)
		chooseAnotherFileButton.setTitleColor(.white, for: .highlighted)
		chooseAnotherFileButton.backgroundColor = Self.fill
		chooseAnotherFileButton.layer.borderColor = Self.fill.cgColor
	}
}
