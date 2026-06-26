import Foundation
import UIKit
import iDenfySDK
// The customization classes (IdenfyCommonColors, *UISettingsV2) live in the
// idenfyviews framework — NOT idenfycore. Confirmed against iDenfySDK-Static
// 9.1.0 (vends idenfycore.xcframework + idenfyviews.xcframework) and the
// official ui-customization example (imports iDenfySDK + idenfyviews).
import idenfyviews

//  Kara dark + gold theme for the iDenfy native SDK.
//
//  The iDenfy dashboard theme does NOT apply to the native SDK — the SDK reads
//  its own static `IdenfyCommonColors` / `*UISettingsV2` properties in code.
//  Setting the master `IdenfyCommonColors` colors cascades to every screen;
//  the per-screen block fixes what the masters can't (cards, button text).
//
//  Source of every identifier: idenfy/iDenfyResources (sdk/ios/uicustomization),
//  matched to the SDK version pinned in the podspec (iDenfySDK-Static 9.1.0).

enum KaraIdenfyTheme {
	// Palette — mirrors apps/native/global.css (.dark), background per request.
	private static let background = karaColor("#090710") // app dark bg override
	private static let gold = karaColor("#E1BE6B") // --gold (accents, links, selection)
	private static let text = karaColor("#FAFAFA") // --foreground
	private static let card = karaColor("#1C1C1E") // --card surfaces
	private static let onButton = karaColor("#090710") // dark text on white buttons
	private static let buttonFill = karaColor("#FAFAFA") // app primary button = white in dark mode
	private static let success = karaColor("#16A34A") // --kara-green
	private static let error = karaColor("#EF4444") // --kara-red

	@MainActor
	static func apply() {
		applyMasterColors()
		applyToolbar()
		applyButtons()
		applyScreenOverrides()
		applyButtonText()
	}

	static func polishVisibleViews(in root: UIView) {
		roundCardsAndControls(in: root)
	}

	// Master palette — cascades to all screens. High confidence: documented names.
	@MainActor
	private static func applyMasterColors() {
		IdenfyCommonColors.idenfyBackgroundColorV2 = background
		IdenfyCommonColors.idenfyMainColorV2 = gold
		IdenfyCommonColors.idenfyMainDarkerColorV2 = gold
		IdenfyCommonColors.idenfySecondColorV2 = text
		// Primary buttons are a gradient — make them solid white (app dark primary).
		IdenfyCommonColors.idenfyGradientColor1V2 = buttonFill
		IdenfyCommonColors.idenfyGradientColor2V2 = buttonFill
		// Light-gray surfaces (privacy-policy cards, accepted-docs cards) default
		// light → white text was invisible on them. Make them dark cards.
		IdenfyCommonColors.idenfyLightGrayColor = card
		// Splash titles/description/spinner default to idenfyBlackV2 (near-black).
		IdenfyCommonColors.idenfyBlackV2 = text
		// Photo-result details card.
		IdenfyCommonColors.idenfyPhotoResultDetailsCardBackgroundColorV2 = card
		// Status colors → match the app's semantic palette.
		IdenfyCommonColors.idenfyStepSuccessColorV2 = success
		IdenfyCommonColors.idenfyStepErrorColorV2 = error
		IdenfyCommonColors.idenfyRedColorV2 = error
		IdenfyCommonColors.idenfyDarkRedErrorColorV2 = error
	}

	@MainActor
	private static func applyToolbar() {
		IdenfyToolbarUISettingsV2.idenfyDefaultToolbarBackgroundColor = background
		IdenfyToolbarUISettingsV2.idenfyDefaultToolbarBackIconTintColor = gold
		// The config plugin overrides iDenfy's logo asset with Kara's wordmark.
		// Keep the logo visible in the otherwise textless SDK toolbar.
		IdenfyToolbarUISettingsV2.idenfyDefaultToolbarLogoIconTintColor = gold
		// Hide the language globe by tinting it to the toolbar background — the
		// SDK exposes no visibility flag for it (only the all-or-nothing
		// idenfyToolbarHidden, which would also remove the close button).
		IdenfyToolbarUISettingsV2.idenfyLanguageSelectionToolbarLanguageSelectionIconTintColor = background
		IdenfyToolbarUISettingsV2.idenfyLanguageSelectionToolbarCloseIconTintColor = gold
	}

	@MainActor
	private static func applyButtons() {
		// Pill corners like the app's rounded-full buttons (note SDK typo "Corder").
		IdenfyButtonsUISettingsV2.idenfyButtonCorderRadius = CGFloat(28)
		IdenfyButtonsUISettingsV2.idenfyChooseAnotherPhotoButtonCornerRadius = CGFloat(28)
	}

	// Per-screen overrides for the flow's screens. Build-risk surface — if the iOS
	// build fails on an unknown member, that property was renamed; remove the line.
	@MainActor
	private static func applyScreenOverrides() {
		// Country + document selection (joined — primary selection screen).
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionBackgroundColor = card
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewContinueButtonEnabledTextColor = onButton
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionHighlightedBackgroundColor = gold
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionHighlightedTextColor = onButton
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionHighlightedBorderColor = gold

		// Document selection (fallback / non-joined).
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewBackgroundColor = background
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCellBackgroundColor = card
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCellHighlightedBackgroundColor = gold
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCellHighlightedTextColor = onButton
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewContinueButtonEnabledTextColor = onButton

		// Photo result: continue = white primary (dark text); retake = gold outline.
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewContinueButtonTextColor = onButton
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewRetakePhotoButtonBackgroundColor = .clear
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewRetakePhotoButtonTextColor = gold
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewRetakePhotoButtonBorderColor = gold
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewDetailsCardBackgroundColor = card

		// PDF result (proof-of-address upload): continue = white primary; retake = gold outline.
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewContinueButtonTextColor = onButton
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewRetakePdfButtonBackgroundColor = .clear
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewRetakePdfButtonTextColor = gold
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewRetakePdfButtonBorderColor = gold
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewDetailsCardBackgroundColor = card

		// Privacy policy: dark info cards (white text was invisible on light cards).
		IdenfyPrivacyPolicyViewUISettingsV2.idenfyPrivacyPolicyCardBackgroundColor = card
		IdenfyPrivacyPolicyViewUISettingsV2.idenfyPrivacyPolicyCardItemTextColor = text
		IdenfyPrivacyPolicyViewUISettingsV2.idenfyPrivacyPolicyCardItemIconColor = gold
		IdenfyPrivacyPolicyViewUISettingsV2.idenfyPrivacyPolicyAgreeButtonTextColor = onButton

		// Language selection (defensive — globe is hidden, but theme it dark in case).
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewBackgroundColor = background
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellBackgroundColor = card
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellHighlightedBackgroundColor = gold
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellHighlightedTextColor = onButton

		// Identification results / face-auth intro / failed — white primary buttons.
		IdenfyIdentificationResultsViewUISettingsV2.idenfyIdentificationResultsViewRetakeButtonTextColor = onButton
		IdenfyFaceAuthenticationInitialViewUISettingsV2.idenfyFaceAuthenticationInitialViewContinueButtonTextColor = onButton
		IdenfyManualReviewingStatusFailedViewUISettingsV2.idenfyManualReviewingStatusFailedContinueButtonTextColor = onButton
	}

	// Primary buttons are now white (gradient → white). Their text defaults to
	// idenfyWhite, which would be invisible on white — so every primary button in
	// the Kara flow (document + selfie + proof-of-address) gets dark text here.
	// ponytail: flow screens only. EID/bank/provider/MFA/NFC/additional-support
	// aren't in this flow; if one ever appears, its primary button needs the same
	// dark text (otherwise white-on-white). Outline buttons (retake/choose-another)
	// stay gold-on-transparent and are set in applyScreenOverrides.
	@MainActor
	private static func applyButtonText() {
		IdenfyPrivacyPolicyViewUISettingsV2.idenfyPrivacyPolicyAgreeButtonTextColor = onButton
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewContinueButtonEnabledTextColor = onButton
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewContinueButtonEnabledTextColor = onButton
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewContinueButtonTextColor = onButton
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewContinueButtonTextColor = onButton
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewContinuePhotoButtonTextColor = onButton
		IdenfyFaceAuthenticationInitialViewUISettingsV2.idenfyFaceAuthenticationInitialViewContinueButtonTextColor = onButton
		IdenfyFaceAuthenticationResultsViewUISettingsV2.idenfyFaceAuthenticationResultsViewContinueButtonTextColor = onButton
		IdenfyIdentificationSuspectedResultsViewUISettingsV2.idenfyIdentificationSuspectedResultsViewContinueButtonTextColor = onButton
		IdenfyManualReviewingStatusFailedViewUISettingsV2.idenfyManualReviewingStatusFailedContinueButtonTextColor = onButton
		IdenfyManualReviewingStatusApprovedViewUISettingsV2.idenfyManualReviewingStatusApprovedContinueButtonTextColor = onButton
		IdenfyQuestionnaireViewUISettingsV2.idenfyQuestionnaireViewContinueButtonEnabledTextColor = onButton
		// In-flow alerts (document not found / MRZ / mismatch / instructions).
		IdenfyDocNotFoundAlertUISettigsV2.idenfyDocNotFoundAlertContinueButtonTextColor = onButton
		IdenfyMrzNotFoundAlertUISettigsV2.idenfyMrzNotFoundAlertContinueButtonTextColor = onButton
		IdenfyMismatchFoundAlertUISettigsV2.idenfyMismatchFoundAlertContinueButtonTextColor = onButton
		IdenfyInstructionAlertUISettigsV2.idenfyInstructionAlertContinueButtonTextColor = onButton
	}

	private static func roundCardsAndControls(in view: UIView) {
		if shouldRound(view) {
			view.layer.cornerRadius = cardRadius(for: view)
			view.layer.cornerCurve = .continuous
			view.clipsToBounds = true
		}

		for subview in view.subviews {
			roundCardsAndControls(in: subview)
		}
	}

	private static func shouldRound(_ view: UIView) -> Bool {
		if view is UIButton { return true }
		if view.layer.borderWidth > 0, view.bounds.height >= 36 { return true }
		if isSameColor(view.backgroundColor, card), view.bounds.height >= 36 {
			return true
		}
		return false
	}

	private static func cardRadius(for view: UIView) -> CGFloat {
		if view is UIButton { return 28 }
		if view.bounds.height >= 64 { return 8 }
		return 6
	}

	// Free function (not a UIColor extension) so it can never collide with an
	// SDK-provided UIColor(hexString:) initializer. Accepts "#RRGGBB".
	private static func karaColor(_ hex: String) -> UIColor {
		var hexValue = hex.trimmingCharacters(in: .whitespacesAndNewlines)
		if hexValue.hasPrefix("#") { hexValue.removeFirst() }
		var rgb: UInt64 = 0
		Scanner(string: hexValue).scanHexInt64(&rgb)
		let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
		let g = CGFloat((rgb & 0x00FF00) >> 8) / 255
		let b = CGFloat(rgb & 0x0000FF) / 255
		return UIColor(red: r, green: g, blue: b, alpha: 1)
	}

	private static func isSameColor(_ lhs: UIColor?, _ rhs: UIColor) -> Bool {
		guard let lhs else { return false }
		var leftRed: CGFloat = 0
		var leftGreen: CGFloat = 0
		var leftBlue: CGFloat = 0
		var leftAlpha: CGFloat = 0
		var rightRed: CGFloat = 0
		var rightGreen: CGFloat = 0
		var rightBlue: CGFloat = 0
		var rightAlpha: CGFloat = 0
		guard
			lhs.getRed(&leftRed, green: &leftGreen, blue: &leftBlue, alpha: &leftAlpha),
			rhs.getRed(&rightRed, green: &rightGreen, blue: &rightBlue, alpha: &rightAlpha)
		else {
			return false
		}
		let tolerance: CGFloat = 0.01
		return abs(leftRed - rightRed) < tolerance &&
			abs(leftGreen - rightGreen) < tolerance &&
			abs(leftBlue - rightBlue) < tolerance &&
			abs(leftAlpha - rightAlpha) < tolerance
	}
}
