import Foundation
import UIKit
import iDenfySDK
import IdenfyLiveness
// The customization classes (IdenfyCommonColors, *UISettingsV2) live in the
// idenfyviews framework — NOT idenfycore. Confirmed against iDenfySDK-Static
// 9.1.0 (vends idenfycore.xcframework + idenfyviews.xcframework) and the
// official ui-customization example (imports iDenfySDK + idenfyviews).
import idenfyviews

//  Kara theme for the iDenfy native SDK: the Écrin direction (KAR-120).
//
//  The iDenfy dashboard theme does NOT apply to the native SDK — the SDK reads
//  its own static `IdenfyCommonColors` properties in code.
//
//  Source of every identifier: idenfy/iDenfyResources (sdk/ios/uicustomization),
//  matched to the SDK version pinned in the podspec (iDenfySDK-Static 9.1.0).

enum KaraIdenfyTheme {
	// Palette: the Écrin tokens of apps/native/lib/theme-tokens.ts (KAR-120),
	// converted from their RGB channels. Internal: KaraIdenfyLayout matches views
	// painted with some of these (see there).
	//
	// Gold marks the one action that moves the flow forward on each screen, and
	// nothing else. A verification flow shows no value (no balance, no amount), so
	// every loader, selection, link, step mark and illustration is neutral. The
	// previous theme did the opposite: white primary button, gold everywhere else.
	static let background = karaColor("#0F0C11") // canvas
	static let text = karaColor("#F5EFE6") // ink
	static let textSecondary = karaColor("#B9AE9F") // ink-2
	private static let textTertiary = karaColor("#85796C") // ink-3
	private static let brand = karaColor("#E8C47F")
	private static let brandPressed = karaColor("#CFA75E")
	private static let onButton = karaColor("#241B0E") // on-brand, the label on gold
	// The Écrin filled gold: a 125 degree gradient with its light band at 60 %.
	// iDenfy only takes two stops (idenfyGradientColor1V2 / 2V2), so those carry
	// the ends and KaraIdenfyLayout puts the middle stop back on the button's own
	// gradient layer.
	static let brandGradient = [karaColor("#E0BB74"), karaColor("#EFD9A8"), karaColor("#D9B264")]
	static let brandGradientLocations: [NSNumber] = [0, 0.6, 1]
	// Translucent surfaces only work flat on the canvas. Anything floating over
	// another screen or over the live camera takes the opaque one, or the content
	// underneath reads straight through it.
	static let surface = text.withAlphaComponent(0.06) // surface
	private static let surfaceHi = text.withAlphaComponent(0.15) // surface-hi
	private static let surfaceSolid = karaColor("#1E1822") // surface-solid
	// The Écrin secondary button (tone-neutral). KaraIdenfyLayout recognises the
	// retake buttons by this exact fill, which is why the disabled fill below is
	// the (visually identical) surface token rather than the same value.
	static let secondaryFill = text.withAlphaComponent(0.08)
	private static let positive = karaColor("#86C99A")
	private static let negative = karaColor("#F0907E")
	// No Écrin token for a warning: the blur and glare cards keep an amber, judged
	// next to the gold button on the same screens.
	private static let warning = karaColor("#E7B008")
	private static let disabledFill = surface
	private static let disabledText = textTertiary

	@MainActor
	static func apply() {
		applyFonts() // must stay first — see applyFonts()
		applyMasterColors()
		applyToolbar()
		applyButtonText()
		applyCornerRadii()
		applyDisabledButtons()
		applySpinners()
		applyCamera()
		applyStatusTints()
		applyBordersAndRowHeights()
		applyBodyTextSizes()
		applySelectionCards()
		applyDarkLists()
		applyPopups()
		KaraIdenfySecondaryButtons.install()
	}

	// The tonal secondary button — retake a photo, choose another file.
	//
	// Its label is repainted through every route the SDK might have used, because
	// they do not override each other: on the alerts, the fill and the border took
	// our values while the text stayed gold, which only happens when the colour is
	// carried by the label's own attributed text. `setTitleColor` and
	// `setAttributedTitle` are both inert against that.
	//
	// Idempotent: one caller is a layout pass, so nothing is reassigned once the
	// label is already ours, and the button never re-invalidates its own layout.
	@MainActor
	static func styleSecondaryButton(_ button: UIButton) {
		guard
			button.backgroundColor != secondaryFill
			|| button.layer.borderWidth > 0
			|| button.titleLabel?.textColor != text
		else { return }

		button.backgroundColor = secondaryFill
		button.layer.borderWidth = 0
		button.setTitleColor(text, for: .normal)
		button.setTitleColor(text, for: .highlighted)

		for state in [UIControl.State.normal, .highlighted] {
			guard let title = button.attributedTitle(for: state), title.length > 0 else {
				continue
			}
			button.setAttributedTitle(repainted(title), for: state)
		}

		// Covers both the title label and any label the SDK adds itself.
		for label in button.subviews.compactMap({ $0 as? UILabel }) {
			if let attributed = label.attributedText, attributed.length > 0 {
				label.attributedText = repainted(attributed)
			}
			label.textColor = text
		}
	}

	private static func repainted(_ string: NSAttributedString) -> NSAttributedString {
		let copy = NSMutableAttributedString(attributedString: string)
		copy.addAttribute(
			.foregroundColor, value: text, range: NSRange(location: 0, length: copy.length)
		)
		return copy
	}

	// Typography — Gabarito, the app's UI font. It is already embedded in the main
	// bundle by the expo-font config plugin (listed in Info.plist `UIAppFonts`).
	//
	// Two hooks on purpose:
	//   - `customFont*FileName` is iDenfy's documented path, and it does work:
	//     `FontsLoader.preloadFontNames()` (first thing every SDK entry point runs)
	//     resolves the name against `Bundle.main`, registers the file, and writes
	//     its real PostScript name back. The HKGrotesk fallback branch never writes
	//     back, so the SDK cannot clobber us.
	//   - the `idenfyFont*V2` names cover the case where that lookup misses.
	//     UIAppFonts has already registered the faces, so `UIFont(name:)` resolves.
	//
	// MUST run before any `*UISettingsV2` font property is read: each one is a
	// `swift_once` static that resolves `UIFont(name:size:)` on first access and
	// caches it for the life of the process. One early read freezes the SDK on
	// HK Grotesk permanently — which is why every entry point calls `apply()`.
	@MainActor
	private static func applyFonts() {
		ConstsIdenfyFonts.customFontBoldFileName = "Gabarito_700Bold.ttf"
		ConstsIdenfyFonts.customFontSemiBoldFileName = "Gabarito_600SemiBold.ttf"
		ConstsIdenfyFonts.customFontRegularFileName = "Gabarito_400Regular.ttf"
		ConstsIdenfyFonts.idenfyFontBoldV2 = "Gabarito-Bold"
		ConstsIdenfyFonts.idenfyFontSemiBoldV2 = "Gabarito-SemiBold"
		ConstsIdenfyFonts.idenfyFontRegularV2 = "Gabarito-Regular"
	}

	// Radii from the Écrin: a pill for buttons, 22 for blocks and panels, 16 for
	// fields. iDenfy defaults to 2-4pt everywhere, which reads as a different
	// product next to ours.
	//
	// 22 is a full pill at iDenfy's ~45pt button height and degrades to a rounded
	// rect on anything taller. Deliberately not larger: `layer.cornerRadius` above
	// half the height distorts the corners, and the SDK exposes no height hook.
	private static let pill = CGFloat(22)
	private static let cardRadius = CGFloat(22)
	private static let fieldRadius = CGFloat(16)
	// The Écrin draws no borders: blocks, fields and lists are carried by their
	// surface alone. iDenfy defaults to 2pt everywhere.
	private static let borderWidth = CGFloat(0)
	private static let rowHeight = CGFloat(56) // matches the `large` button height

	// The retake / choose-another buttons take their radius from the shared
	// `idenfyButtonCorderRadius` above; their colours cannot be set here at all,
	// see styleSecondaryButton().
	@MainActor
	private static func applyCornerRadii() {
		IdenfyButtonsUISettingsV2.idenfyButtonCorderRadius = pill

		// Cards and panels.
		IdenfyPrivacyPolicyViewUISettingsV2.idenfyPrivacyPolicyCardBorderRadius = cardRadius
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewDetailsCardCornerRadius = cardRadius
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewDetailsCardCornerRadius = cardRadius
		IdenfyInstructionAlertUISettigsV2.idenfyInstructionAlertDetailsCardCornerRadius = cardRadius
		IdenfyLoadingHUDUISettingsV2.idenfyLoadingHUDCornerRadius = cardRadius

		// The country field, the document chips and the country search are fields,
		// not buttons: they take the Écrin field radius.
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionCornerRadius = fieldRadius
		IdenfyIssuedCountryViewUISettingsV2.idenfyIssuedCountryViewCountryViewCorderRadius = fieldRadius
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarCorderRadius = fieldRadius

		// List panels stay on the card radius — they are tall surfaces.
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCornerRadius = cardRadius
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCornerRadius = cardRadius
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCornerRadius = cardRadius

		// Captured-photo preview and the cropping frame.
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewPhotoCornerRadius = cardRadius
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewCroppingViewCornerRadius = cardRadius
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewCroppingRectangleCornerRadius = cardRadius
	}


	// The connectivity toasts are suppressed: the app has its own
	// ConnectivityProvider, so iDenfy's slide-in duplicated a message the user
	// already gets, in a different visual language.
	//
	// ponytail: painted out rather than disabled. The SDK exposes no flag and no
	// view-injection hook for these two, so every colour goes clear and the icon
	// is overridden with an empty asset. The view still slides in and out, it just
	// draws nothing.
	@MainActor
	private static func applyPopups() {
		IdenfyInternetConnectionPopupViewUISettingsV2.IdenfyInternetConnectionPopupViewBackgroundColor = .clear
		IdenfyInternetConnectionPopupViewUISettingsV2.IdenfyInternetConnectionPopupViewTextViewColor = .clear
		IdenfyInternetStabilityPopupViewUISettingsV2.idenfyInternetStabilityPopupViewBackgroundColor = .clear
		IdenfyInternetStabilityPopupViewUISettingsV2.idenfyInternetStabilityPopupViewTextViewColor = .clear
		IdenfyInternetStabilityPopupViewUISettingsV2.idenfyInternetStabilityPopupViewImageViewTintColor = .clear
	}

	@MainActor
	static func makeLivenessSettings() -> IdenfyLivenessUISettings {
		let settings = IdenfyLivenessUISettings()
		// The face scan itself has no action: the user holds still. So the oval,
		// its progress and the frame are neutral, and the only gold is the ready
		// screen's button below.
		settings.idenfyLivenessPrimaryColor = text
		settings.idenfyLivenessAccentColor = text
		settings.idenfyLivenessTextColor = text
		// Floats over the live camera, so opaque (see surfaceSolid).
		settings.livenessFeedbackBackgroundColor = surfaceSolid
		settings.livenessFeedbackFontColor = text
		settings.livenessFrameBackgroundColor = background
		// Borderless, as on Android: the frame is the full-bleed container.
		settings.livenessFrameColor = background
		settings.livenessIdentificationOvalProgressColor1 = text
		settings.livenessIdentificationProgressStrokeColor = textTertiary
		settings.livenessIdentificationOvalProgressColor2 = text
		settings.livenessOverlayBackgroundColor = background
		settings.livenessReadyScreenBackgroundColors = [background, background]
		settings.livenessReadyScreenTextBackgroundColor = background
		settings.livenessReadyScreenForegroundColor = onButton
		// "I'm ready" starts the scan: the one gold element of the face step.
		// FaceTec takes a single colour here, so it gets the flat brand gold.
		settings.livenessReadyScreenButtonBackgroundNormalColor = brand
		settings.livenessReadyScreenButtonBackgroundHighlightedColor = brandPressed
		settings.livenessReadyScreenButtonBackgroundDisabledColor = disabledFill
		settings.livenessReadyScreenButtonCornerRadius = Int32(pill)
		settings.livenessResultScreenForegroundColor = text
		settings.livenessResultScreenIndicatorColor = textSecondary
		settings.livenessResultScreenUploadProgressFillColor = text
		// FaceTec always draws something here: turning the branding off just fell
		// back to its own "yourAppLOGO" placeholder rather than showing nothing.
		// So the Kara wordmark goes back, untinted: the asset itself is drawn in
		// cream (apps/native/assets/idenfy), since gold there would be decorative
		// and sit right above the gold button.
		if let logo = karaImage("KaraBrandingLogo") {
			settings.livenessOverlayBrandingImage = logo
			settings.livenessReadyScreenShowBrandingImage = true
		}
		return settings
	}

	// Looks in this module's bundle first, then the app's. Our images ship in the
	// app's asset catalog (config plugin), but linkage decides which bundle a
	// framework's `Bundle(for:)` resolves to, so both are tried.
	@MainActor
	static func karaImage(_ name: String) -> UIImage? {
		let bundles = [Bundle(for: KaraBundleToken.self), Bundle.main]
		for bundle in bundles {
			if let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
				return image
			}
		}
		return nil
	}

	// Master palette — cascades to all screens. High confidence: documented names.
	@MainActor
	private static func applyMasterColors() {
		// Opaque. KaraIdenfyLayout swaps this exact colour for the app's background
		// image, screen by screen, and only clears a view once the image is behind
		// it. Making the token itself transparent leaked the live camera through
		// the photo-result screen, which the delegate never gets a callback for.
		IdenfyCommonColors.idenfyBackgroundColorV2 = background
		// The SDK's accent: links, loaders, step marks, selections, checkboxes. All
		// of it goes neutral in one move; the one gold element per screen is the
		// primary button, painted by the gradient below.
		IdenfyCommonColors.idenfyMainColorV2 = text
		IdenfyCommonColors.idenfyMainDarkerColorV2 = text
		IdenfyCommonColors.idenfySecondColorV2 = text
		// Primary buttons are a two-stop gradient: the two ends of the Écrin gold.
		// KaraIdenfyLayout adds the light band in the middle.
		IdenfyCommonColors.idenfyGradientColor1V2 = brandGradient[0]
		IdenfyCommonColors.idenfyGradientColor2V2 = brandGradient[2]
		IdenfyButtonsUISettingsV2.idenfyGradientButtonColorStart = brandGradient[0]
		IdenfyButtonsUISettingsV2.idenfyGradientButtonColorEnd = brandGradient[2]
		// Light-gray surfaces (privacy-policy cards, accepted-docs cards) default
		// light → white text was invisible on them. Make them dark cards.
		IdenfyCommonColors.idenfyLightGrayColor = surface
		// Near-black master color used for content drawn on light surfaces (splash
		// titles, the PDF-result file icon, spinners). On our dark backgrounds it
		// renders black-on-black (invisible) — remap to light. Set both V1 + V2.
		IdenfyCommonColors.idenfyBlackV2 = text
		IdenfyCommonColors.idenfyBlack = text
		// Photo-result details card.
		IdenfyCommonColors.idenfyPhotoResultDetailsCardBackgroundColorV2 = surface
		// Status colors → match the app's semantic palette.
		IdenfyCommonColors.idenfyStepSuccessColorV2 = positive
		IdenfyCommonColors.idenfyStepErrorColorV2 = negative
		IdenfyCommonColors.idenfyRedColorV2 = negative
		IdenfyCommonColors.idenfyDarkRedErrorColorV2 = negative
		// Loading HUD (full-screen spinner overlay): it floats over the previous
		// screen, so the opaque surface, with light text.
		IdenfyLoadingHUDUISettingsV2.idenfyLoadingHUDBackgroundColor = surfaceSolid
		IdenfyLoadingHUDUISettingsV2.idenfyLoadingHUDTitleColor = text
		IdenfyLoadingHUDUISettingsV2.idenfyLoadingHUDDescriptionColor = textSecondary
		// Nothing to do while the splash loads, so no gold.
		IdenfySplashScreenViewUISettingsV2.idenfySplashScreenViewSpinnerTintColor = textSecondary
	}

	@MainActor
	private static func applyToolbar() {
		// Transparent so the background image inserted by KaraIdenfyLayout shows
		// through, instead of banding against it.
		IdenfyToolbarUISettingsV2.idenfyDefaultToolbarBackgroundColor = .clear
		// The default toolbar draws a black drop shadow, which reads as a darker
		// band separating the header from the page. Our headers have no shadow.
		IdenfyToolbarUISettingsV2.idenfyDefaultToolbarShadowOpacity = 0
		// Pinned so the header keeps one height across the flow instead of varying
		// with each screen's content.
		IdenfyToolbarUISettingsV2.idenfyToolbarHeight = 60
		// Back arrow and close icon in cream.
		IdenfyToolbarUISettingsV2.idenfyDefaultToolbarBackIconTintColor = text
		IdenfyToolbarUISettingsV2.idenfyCameraPreviewSessionToolbarBackIconTintColor = text
		IdenfyToolbarUISettingsV2.idenfyLanguageSelectionToolbarCloseIconTintColor = text
		// The language globe defaults to the main colour; pinned here so it stays
		// with the other toolbar icons whatever that colour becomes.
		IdenfyToolbarUISettingsV2.idenfyLanguageSelectionToolbarLanguageSelectionIconTintColor = text
		IdenfyToolbarUISettingsV2.idenfyFaceAuthToolbarLanguageSelectionIconTintColor = text
		// The toolbar has no title-text property: its centre is an image view. The
		// app ships a "KYC" wordmark under iDenfy's own asset name, and this tint
		// colours it — so the shape comes from the asset, the colour stays here.
		IdenfyToolbarUISettingsV2.idenfyDefaultToolbarLogoIconTintColor = text
	}

	@MainActor
	private static func applyButtonText() {
		IdenfyPrivacyPolicyViewUISettingsV2.idenfyPrivacyPolicyAgreeButtonTextColor = onButton
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewContinueButtonEnabledTextColor = onButton
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewContinueButtonEnabledTextColor = onButton
		// Document-capture onboarding screen ("Front of the ID card"). Its continue
		// button text was unset → light on the light fill (invisible). Force the
		// on-gold label in both states.
		IdenfyStaticCameraOnBoardingViewUISettingsV2.idenfyCameraOnBoardingEnabledContinueButtonTextColor = onButton
		IdenfyStaticCameraOnBoardingViewUISettingsV2.idenfyCameraOnBoardingDisabledContinueButtonTextColor = onButton
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewContinueButtonTextColor = onButton
		// The retake buttons take their LABEL colour from the border setting, not
		// from the text one, which is inert. Setting the border to the fill is what
		// made the label vanish through seven attempts. So: tonal fill, cream border,
		// and the label comes out cream. The border itself is never drawn, its width
		// is zeroed at layout (KaraIdenfyLayout, KaraIdenfyCameraResultView).
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewRetakePhotoButtonBackgroundColor = secondaryFill
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewRetakePhotoButtonBorderColor = text
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewRetakePdfButtonBackgroundColor = secondaryFill
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewRetakePdfButtonBorderColor = text
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewChooseAnotherPhotoButtonBackgroundColor = secondaryFill
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewChooseAnotherPhotoButtonBorderColor = text
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
		// The highlighted document name used to be picked out in gold. It stays
		// picked out, by contrast: full cream on a secondary-cream sentence.
		IdenfyDocNotFoundAlertUISettigsV2.idenfyDocNotFoundAlertCommonInformationDescriptionTextColor = textSecondary
		IdenfyDocNotFoundAlertUISettigsV2.idenfyDocNotFoundAlertDescriptionHighlightedTextColor = text
		// End-of-flow and permission screens. Same light-on-light trap, and these
		// are the ones a user actually lands on when something goes wrong
		// (cancelled session, denied camera, NFC).
		IdenfyAdditionalSupportViewUISettingsV2.idenfyAdditionalSupportViewContinueButtonTextColor = onButton
		IdenfyIdentificationResultsViewUISettingsV2.idenfyIdentificationResultsViewRetakeButtonTextColor = onButton
		IdenfyManualReviewingStatusWaitingViewUISettingsV2.idenfyManualReviewingStatusWaitingStopWaitingButtonTextColor = onButton
		IdenfyCameraPermissionViewUISettingsV2.idenfyCameraPermissionViewGoToSettingsButtonTextColor = onButton
		IdenfyIssuedCountryViewUISettingsV2.idenfyIssuedCountryViewBeginIdentificationButtonTextColor = onButton
		IdenfyNFCReadingViewUISettingsV2.idenfyNFCReadingContinueButtonTextColor = onButton
		IdenfyNFCReadingTimeOutViewUISettingsV2.idenfyNFCReadingTimeOutContinueButtonTextColor = onButton
		IdenfyNFCRequiredViewUISettingsV2.idenfyNFCRequiredContinueButtonTextColor = onButton
	}

	// Disabled primary buttons: no gold at all, as in the Écrin (a pale gold still
	// reads as an action). Tonal fill, tertiary label.
	@MainActor
	private static func applyDisabledButtons() {
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewContinueButtonDisabledBackgroundColor = disabledFill
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewContinueButtonDisabledTextColor = disabledText
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewContinueButtonDisabledBackgroundColor = disabledFill
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewContinueButtonDisabledTextColor = disabledText
		IdenfyStaticCameraOnBoardingViewUISettingsV2.idenfyCameraOnBoardingDisabledContinueButtonBackgroundColor = disabledFill
		IdenfyStaticCameraOnBoardingViewUISettingsV2.idenfyCameraOnBoardingDisabledContinueButtonTextColor = disabledText
		IdenfyMismatchFoundAlertUISettigsV2.idenfyMismatchFoundAlertContinueDisabledButtonBackgroundColor = disabledFill
		IdenfyMismatchFoundAlertUISettigsV2.idenfyMismatchFoundAlertContinueDisabledButtonTextColor = disabledText
		IdenfyQuestionnaireViewUISettingsV2.idenfyQuestionnaireViewContinueButtonDisabledBackgroundColor = disabledFill
		IdenfyQuestionnaireViewUISettingsV2.idenfyQuestionnaireViewContinueButtonDisabledTextColor = disabledText
	}

	// A spinner inside a gold button takes the on-gold colour. Everywhere else a
	// loader means waiting, which is no action, so it is cream like the other
	// loaders the accent colour reaches.
	@MainActor
	private static func applySpinners() {
		IdenfyPrivacyPolicyViewUISettingsV2.idenfyPrivacyPolicyAgreeButtonLoadingSpinnerTintColor = onButton
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewContinueButtonLoadingSpinnerTintColor = onButton
		IdenfyQuestionnaireViewUISettingsV2.idenfyQuestionnaireViewContinueButtonLoadingSpinnerTintColor = onButton
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewCountryLoadingSpinnerTintColor = text
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryLoadingSpinnerTintColor = text
		IdenfyLoadingHUDUISettingsV2.idenfyLoadingSpinnerTintColor = text
	}

	// The shutter is the action of the camera screens: gold fill, on-gold icon,
	// darker when pressed. Shape and size stay the SDK's, only the fill changes.
	// The upload shortcut next to it is secondary, so cream.
	@MainActor
	private static func applyCamera() {
		IdenfyDocumentCameraSessionUISettingsV2.idenfyDocumentCameraPreviewSessionTakePhotoButtonUnFocusedBackgroundColor = brand
		IdenfyDocumentCameraSessionUISettingsV2.idenfyDocumentCameraPreviewSessionTakePhotoButtonUnFocusedTintColor = onButton
		IdenfyDocumentCameraSessionUISettingsV2.idenfyDocumentCameraPreviewSessionTakePhotoButtonFocusedBackgroundColor = brandPressed
		IdenfyDocumentCameraSessionUISettingsV2.idenfyDocumentCameraPreviewSessionTakePhotoButtonFocusedTintColor = onButton
		IdenfyDocumentCameraSessionUISettingsV2.idenfyDocumentCameraPreviewSessionUploadPhotoButtonTintColor = text
		IdenfyFaceCameraSessionUISettingsV2.idenfyFaceCameraPreviewSessionTakePhotoButtonUnFocusedBackgroundColor = brand
		IdenfyFaceCameraSessionUISettingsV2.idenfyFaceCameraPreviewSessionTakePhotoButtonUnFocusedTintColor = onButton
		IdenfyFaceCameraSessionUISettingsV2.idenfyFaceCameraPreviewSessionTakePhotoButtonFocusedBackgroundColor = brandPressed
		IdenfyFaceCameraSessionUISettingsV2.idenfyFaceCameraPreviewSessionTakePhotoButtonFocusedTintColor = onButton
		IdenfyFaceCameraSessionUISettingsV2.idenfyDocumentCameraPreviewSessionUploadPhotoButtonTintColor = text
	}

	// Status tints. Every "light" colour below is a light-mode pastel (#FFEBEE,
	// #FFF3E0, #E8F5E9, ...) that renders as a glaring near-white block on our
	// background — the blur/glare and auto-capture-failure cards use them. Swap
	// for 12% washes of the app's semantic colours, the way our own cards do it.
	@MainActor
	private static func applyStatusTints() {
		IdenfyCommonColors.idenfyErrorLightRedColorV2 = negative.withAlphaComponent(0.12)
		IdenfyCommonColors.idenfyWarningLightYellowV2 = warning.withAlphaComponent(0.12)
		IdenfyCommonColors.idenfyBackgroundGreenV2 = positive.withAlphaComponent(0.12)
		IdenfyCommonColors.idenfyWarningYellowV2 = warning
		// The Écrin has no blue: information is neutral.
		IdenfyCommonColors.idenfyLightBlueColor = secondaryFill
		IdenfyCommonColors.idenfyBlueColor = textSecondary
		IdenfyCommonColors.idenfyBorderGreenV2 = positive
		IdenfyCommonColors.idenfyFaceDetectedColor = positive
		IdenfyCommonColors.idenfyFaceNotDetectedColor = textTertiary
		// Processing steps: a done step reads as done, a step in progress stays
		// quiet. Both followed the accent before.
		IdenfyIdentificationResultsViewUISettingsV2.idenfyIdentificationResultsDividerIconStatusSuccessTintColor = positive
		IdenfyIdentificationResultsViewUISettingsV2.idenfyIdentificationResultsDividerIconStatusLoadingTintColor = textTertiary
		// iDenfy purple survives in a few highlight states. Neutral, like every
		// other accent: a cream mark on a tonal surface.
		IdenfyCommonColors.idenfyPurpleV2 = text
		IdenfyCommonColors.idenfyPurpleTextV2 = text
		IdenfyCommonColors.idenfyBackgroundPurpleV2 = surface
	}

	// Borders off (see borderWidth). Row heights go to 56 to match our large
	// control height (the document list already ships 56).
	@MainActor
	private static func applyBordersAndRowHeights() {
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewBorderWidth = borderWidth
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCellBorderWidth = borderWidth
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarBorderWidth = borderWidth
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewBorderWidth = borderWidth
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCellBorderWidth = borderWidth
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewBorderWidth = borderWidth
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellBorderWidth = borderWidth
		IdenfyIssuedCountryViewUISettingsV2.idenfyIssuedCountryViewCountryViewBorderWidth = borderWidth
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewCroppingViewBorderWidth = borderWidth
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewPhotoBorderWidth = borderWidth

		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewCountryTableViewCellHeight = rowHeight
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCellHeight = rowHeight
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellHeight = rowHeight
	}

	// The SDK sets its screen descriptions at 13 on half the screens and 15 on the
	// other half. Unify at 15 — closer to our `text-base` and the size the privacy
	// screen already uses. Descriptions wrap, so nothing can truncate.
	@MainActor
	private static func applyBodyTextSizes() {
		let body = UIFont(name: ConstsIdenfyFonts.idenfyFontRegularV2, size: 15)
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewDescriptionFont = body
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDescriptionFont = body
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewDescriptionFont = body
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewDescriptionFont = body
		IdenfyCameraPermissionViewUISettingsV2.idenfyCameraPermissionViewDescriptionFont = body
		IdenfyIdentificationResultsViewUISettingsV2.idenfyIdentificationResultsViewDescriptionFont = body
		IdenfyIssuedCountryViewUISettingsV2.idenfyIssuedCountryViewDescriptionFont = body
		IdenfyManualReviewingStatusFailedViewUISettingsV2.idenfyManualReviewingStatusFailedCommonInformationDescriptionFont = body
		IdenfyManualReviewingStatusWaitingViewUISettingsV2.idenfyManualReviewingStatusWaitingCommonInformationDescriptionFont = body
	}

	// Country + document selection cards (the joined first screen). iDenfy's
	// defaults render the country field and unselected cards as grey/white with
	// near-invisible text — the country field looked disabled. Every card is an
	// Écrin field: surface, no border, readable text.
	@MainActor
	private static func applySelectionCards() {
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionBackgroundColor = surface
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionTextColor = text
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionBorderWidth = borderWidth
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionBorderColor = .clear
		// A choice is never gold, and no longer a white slab either: the selected
		// card lifts to the higher surface, as the Écrin's exclusive choice does.
		// The gold on this screen is the continue button.
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionHighlightedBackgroundColor = surfaceHi
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionHighlightedTextColor = text
		// The selected card draws its own border with no width knob, so match it to
		// the fill and let the shape carry the state.
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionHighlightedBorderColor = surfaceHi
		// Same rule on the standalone document list.
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCellHighlightedBackgroundColor = surfaceHi
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCellHighlightedTextColor = text
	}

	// Full-screen picker lists (language, document country). iDenfy defaults both
	// tables to a white panel with near-invisible grey text. Each list is an Écrin
	// block: one surface, transparent rows, the selected row lifted, never gold
	// (picking a row only returns to the previous screen, it is not an action).
	//
	// The rows are clear rather than painted with the background token on
	// purpose: KaraIdenfyLayout puts the background image behind every view of
	// that colour, and one image per row would repeat the canvas glow down the
	// list.
	@MainActor
	private static func applyDarkLists() {
		// Language selection.
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewBackgroundColor = surface
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellBackgroundColor = .clear
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellTextColor = text
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellHighlightedBackgroundColor = surfaceHi
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellHighlightedTextColor = text
		// Document country selection (the dropdown list opened from the country field).
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewBackgroundColor = surface
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCellBackgroundColor = .clear
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCellTextColor = text
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCellHighlightedBackgroundColor = surfaceHi
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCellHighlightedTextColor = text
		// Search field at the top of the country list — default white box. An
		// Écrin field: surface, cream typed text, tertiary placeholder and icon.
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarBackgroundColor = surface
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarTextColor = text
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarHintTextColor = textTertiary
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarSearchIconTintColor = textTertiary
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
