import Foundation
import UIKit
import iDenfySDK
import IdenfyLiveness
// The customization classes (IdenfyCommonColors, *UISettingsV2) live in the
// idenfyviews framework — NOT idenfycore. Confirmed against iDenfySDK-Static
// 9.1.0 (vends idenfycore.xcframework + idenfyviews.xcframework) and the
// official ui-customization example (imports iDenfySDK + idenfyviews).
import idenfyviews

//  Kara dark + gold theme for the iDenfy native SDK.
//
//  The iDenfy dashboard theme does NOT apply to the native SDK — the SDK reads
//  its own static `IdenfyCommonColors` properties in code.
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
	private static let buttonFill = karaColor("#FAFAFA")
	private static let success = karaColor("#16A34A") // --kara-green
	private static let error = karaColor("#EF4444") // --kara-red

	@MainActor
	static func apply() {
		applyMasterColors()
		applyToolbar()
		applyButtonText()
		applySelectionCards()
		applyDarkLists()
		applyPopups()
	}

	// Internet connection / stability popups (the slide-in toasts). Default light
	// containers → dark card with light text.
	@MainActor
	private static func applyPopups() {
		IdenfyInternetConnectionPopupViewUISettingsV2.IdenfyInternetConnectionPopupViewBackgroundColor = card
		IdenfyInternetConnectionPopupViewUISettingsV2.IdenfyInternetConnectionPopupViewTextViewColor = text
		IdenfyInternetStabilityPopupViewUISettingsV2.idenfyInternetStabilityPopupViewBackgroundColor = card
		IdenfyInternetStabilityPopupViewUISettingsV2.idenfyInternetStabilityPopupViewTextViewColor = text
		IdenfyInternetStabilityPopupViewUISettingsV2.idenfyInternetStabilityPopupViewImageViewTintColor = gold
	}

	@MainActor
	static func makeLivenessSettings() -> IdenfyLivenessUISettings {
		let settings = IdenfyLivenessUISettings()
		settings.idenfyLivenessPrimaryColor = gold
		settings.idenfyLivenessAccentColor = gold
		settings.idenfyLivenessTextColor = text
		settings.livenessFeedbackBackgroundColor = card
		settings.livenessFeedbackFontColor = text
		settings.livenessFrameBackgroundColor = background
		settings.livenessFrameColor = gold
		settings.livenessIdentificationOvalProgressColor1 = gold
		settings.livenessIdentificationProgressStrokeColor = gold
		settings.livenessIdentificationOvalProgressColor2 = gold
		settings.livenessOverlayBackgroundColor = background
		settings.livenessReadyScreenBackgroundColors = [background, background]
		settings.livenessReadyScreenTextBackgroundColor = background
		settings.livenessReadyScreenForegroundColor = onButton
		settings.livenessReadyScreenButtonBackgroundNormalColor = gold
		settings.livenessReadyScreenButtonBackgroundHighlightedColor = gold
		settings.livenessReadyScreenButtonBackgroundDisabledColor = card
		settings.livenessResultScreenForegroundColor = text
		settings.livenessResultScreenIndicatorColor = gold
		settings.livenessResultScreenUploadProgressFillColor = gold
		// Replace the "yourAppLOGO" placeholder on the ready screen with the Kara
		// wordmark (bundled in the pod's KaraIdenfyResources). No tint → the gold
		// logo shows in its own colors.
		if let logo = brandingLogo() {
			settings.livenessOverlayBrandingImage = logo
			settings.livenessReadyScreenShowBrandingImage = true
		}
		return settings
	}

	// Loads the bundled Kara logo. Looks in the pod's resource bundle first, then
	// the host/main bundle — covers both static and dynamic framework linkage.
	@MainActor
	private static func brandingLogo() -> UIImage? {
		let host = Bundle(for: KaraBundleToken.self)
		let bundles = [
			host.url(forResource: "KaraIdenfyResources", withExtension: "bundle")
				.flatMap(Bundle.init(url:)),
			host,
			Bundle.main,
		].compactMap { $0 }
		for bundle in bundles {
			if let image = UIImage(named: "KaraBrandingLogo", in: bundle, compatibleWith: nil) {
				return image
			}
		}
		return nil
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
		// Near-black master color used for content drawn on light surfaces (splash
		// titles, the PDF-result file icon, spinners). On our dark backgrounds it
		// renders black-on-black (invisible) — remap to light. Set both V1 + V2.
		IdenfyCommonColors.idenfyBlackV2 = text
		IdenfyCommonColors.idenfyBlack = text
		// Photo-result details card.
		IdenfyCommonColors.idenfyPhotoResultDetailsCardBackgroundColorV2 = card
		// Status colors → match the app's semantic palette.
		IdenfyCommonColors.idenfyStepSuccessColorV2 = success
		IdenfyCommonColors.idenfyStepErrorColorV2 = error
		IdenfyCommonColors.idenfyRedColorV2 = error
		IdenfyCommonColors.idenfyDarkRedErrorColorV2 = error
		// Loading HUD (full-screen spinner overlay): default light container →
		// dark card with light text.
		IdenfyLoadingHUDUISettingsV2.idenfyLoadingHUDBackgroundColor = card
		IdenfyLoadingHUDUISettingsV2.idenfyLoadingHUDTitleColor = text
		IdenfyLoadingHUDUISettingsV2.idenfyLoadingHUDDescriptionColor = text
	}

	@MainActor
	private static func applyToolbar() {
		IdenfyToolbarUISettingsV2.idenfyDefaultToolbarBackgroundColor = background
		IdenfyToolbarUISettingsV2.idenfyDefaultToolbarBackIconTintColor = gold
		IdenfyToolbarUISettingsV2.idenfyLanguageSelectionToolbarCloseIconTintColor = gold
		// Hide the iDenfy wordmark: the toolbar exposes no title-text property, so
		// we can't show "Identité" — tint the logo to the background to make it
		// vanish (only the all-or-nothing idenfyToolbarHidden would remove it
		// otherwise, which would also drop the close/back button).
		IdenfyToolbarUISettingsV2.idenfyDefaultToolbarLogoIconTintColor = background
	}

	@MainActor
	private static func applyButtonText() {
		IdenfyPrivacyPolicyViewUISettingsV2.idenfyPrivacyPolicyAgreeButtonTextColor = onButton
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewContinueButtonEnabledTextColor = onButton
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewContinueButtonEnabledTextColor = onButton
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCellHighlightedTextColor = onButton
		// Document-capture onboarding screen ("Front of the ID card"). Its continue
		// button text was unset → white-on-white (invisible). Keep the button white,
		// force dark text in both states.
		IdenfyStaticCameraOnBoardingViewUISettingsV2.idenfyCameraOnBoardingEnabledContinueButtonTextColor = onButton
		IdenfyStaticCameraOnBoardingViewUISettingsV2.idenfyCameraOnBoardingDisabledContinueButtonTextColor = onButton
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewContinueButtonTextColor = onButton
		// "Take a new photo" (retake): default gold text sits on a light button →
		// low contrast. Force dark text — on both the photo and PDF result screens.
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewRetakePhotoButtonTextColor = onButton
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewRetakePdfButtonTextColor = onButton
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

	// Country + document selection cards (the joined first screen). iDenfy's
	// defaults render the country field and unselected cards as grey/white with
	// near-invisible text — the country field looked disabled. Make every card a
	// borderless dark surface with readable text; the selected card gets a solid
	// gold fill with dark text.
	@MainActor
	private static func applySelectionCards() {
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionBackgroundColor = card
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionTextColor = text
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionBorderWidth = CGFloat(0)
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionHighlightedBackgroundColor = gold
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionHighlightedTextColor = onButton
		// The selected card draws a separate highlighted border (no width knob for
		// it) → match it to the gold fill so it blends away. No visible border.
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionHighlightedBorderColor = gold
	}

	// Full-screen picker lists (language, document country). iDenfy defaults both
	// tables to a white panel with near-invisible grey text. Make them dark lists
	// (matching the toolbar) with readable text; the highlighted row gets a gold
	// fill with dark text.
	@MainActor
	private static func applyDarkLists() {
		// Language selection.
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewBackgroundColor = background
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellBackgroundColor = background
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellTextColor = text
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellHighlightedBackgroundColor = gold
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellHighlightedTextColor = onButton
		// Document country selection (the dropdown list opened from the country field).
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewBackgroundColor = background
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCellBackgroundColor = background
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCellTextColor = text
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCellHighlightedBackgroundColor = gold
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCellHighlightedTextColor = onButton
		// Search field at the top of the country list — default white box. Make it
		// a dark card with light typed text and a gold search icon.
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarBackgroundColor = card
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarTextColor = text
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarHintTextColor = text
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarSearchIconTintColor = gold
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
}

// Anchors `Bundle(for:)` to this module's binary so bundled resources resolve
// regardless of how the SDK is linked.
private final class KaraBundleToken {}
