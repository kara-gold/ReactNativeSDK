import Foundation
import UIKit
import idenfycore
import idenfyviews

//  The screen before the camera, with a line pointing at the file option.
//
//  We briefly put a "choose a file" button here that jumped straight to the
//  picker. It could not work: whether the upload opens a file chooser at all is
//  decided by `canUpload` / `canUploadPDF` in the session config, per document
//  type and per step, with no app-side override. And the picker belongs to the
//  camera controller, so the camera always loaded behind it and cancelling left
//  the user there.
//
//  So the flow stays iDenfy's own, and this screen just says where the button
//  is. Injected through `IdenfyViewsBuilderV2.withStaticCameraOnBoardingView`.
@MainActor
final class KaraIdenfyDocumentOnBoardingView: StaticCameraOnBoardingViewV2 {
	private static let spacing = CGFloat(12)
	private var installed = false

	override func layoutSubviews() {
		super.layoutSubviews()
		guard !installed, bounds.width > 0 else { return }
		installed = true
		replaceProofOfAddressCopy()
		addFileHint()
	}

	// The proof-of-address instructions come from the iDenfy dashboard: they list
	// no accepted document, so people bring the wrong paper. Ours name them first,
	// then keep the SDK's constraints. Only this step is touched; the identity
	// steps keep whatever the dashboard sends.
	private func replaceProofOfAddressCopy() {
		guard currentStep == .UTILITY_BILL || currentStep == .SECOND_UTILITY_BILL else {
			return
		}
		// From React Native first, so the list is correctable over the air; the
		// bundled table is only the fallback for an older JS bundle.
		let fallback = Bundle.main.localizedString(
			forKey: "kara_poa_instructions", value: "", table: "Idenfy"
		)
		let text = KaraIdenfyCopy.proofOfAddressInstructions
			?? (fallback == "kara_poa_instructions" ? "" : fallback)
		guard !text.isEmpty else { return }

		let label = idenfyUILabelCameraOnBoardingCommonInformationDescription
		label.text = text
		label.numberOfLines = 0
		label.textAlignment = .left
	}

	private func addFileHint() {
		let text = Bundle.main.localizedString(
			forKey: "kara_file_hint", value: "", table: "Idenfy"
		)
		let anchor = idenfyUIEnabledButtonCameraOnBoardingContinue
		guard !text.isEmpty, text != "kara_file_hint", let parent = anchor.superview
		else { return }

		let label = UILabel()
		label.text = text
		label.font = UIFont(name: ConstsIdenfyFonts.idenfyFontRegularV2, size: 13)
		label.textColor = UIColor.white.withAlphaComponent(0.6)
		label.textAlignment = .center
		label.numberOfLines = 0
		label.translatesAutoresizingMaskIntoConstraints = false
		parent.addSubview(label)

		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: anchor.leadingAnchor),
			label.trailingAnchor.constraint(equalTo: anchor.trailingAnchor),
			label.bottomAnchor.constraint(equalTo: anchor.topAnchor, constant: -Self.spacing),
		])
	}
}
