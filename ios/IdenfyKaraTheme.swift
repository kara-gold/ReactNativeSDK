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
	// Our cards are `bg-white/5` over a `border-white/10`, not an opaque grey.
	// The app is one background image away from black, so a translucent surface
	// picks up the gradient underneath instead of flattening it.
	private static let card = UIColor.white.withAlphaComponent(0.05)
	private static let onButton = karaColor("#090710") // dark text on white buttons
	private static let buttonFill = karaColor("#FAFAFA")
	private static let secondaryFill = karaColor("#262626") // --secondary, our grey button
	private static let success = karaColor("#16A34A") // --kara-green
	private static let error = karaColor("#EF4444") // --kara-red
	private static let warning = karaColor("#E7B008") // --kara-yellow
	private static let info = karaColor("#3B82F6") // --kara-blue
	// Opacity scale, taken from the app's Button/border classes: white/10 for a
	// hairline border, white/12 for a disabled fill, white/40 for disabled text.
	private static let border = UIColor.white.withAlphaComponent(0.1)
	private static let disabledFill = UIColor.white.withAlphaComponent(0.12)
	private static let disabledText = UIColor.white.withAlphaComponent(0.4)

	@MainActor
	static func apply() {
		applyFonts() // must stay first — see applyFonts()
		applyMasterColors()
		applyToolbar()
		applyButtonText()
		applyCornerRadii()
		applySecondaryButtons()
		applyDisabledButtons()
		applySpinners()
		applyStatusTints()
		applyBordersAndRowHeights()
		applyBodyTextSizes()
		applySelectionCards()
		applyDarkLists()
		applyPopups()
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

	// Two radii, mirroring the app: `rounded-full` for buttons, `rounded-2xl`
	// (16pt) for every other surface. iDenfy defaults to 2-4pt everywhere, which
	// reads as a different product next to ours.
	//
	// 22 is a full pill at iDenfy's ~45pt button height and degrades to a rounded
	// rect on anything taller. Deliberately not larger: `layer.cornerRadius` above
	// half the height distorts the corners, and the SDK exposes no height hook.
	private static let pill = CGFloat(22)
	private static let cardRadius = CGFloat(16)
	private static let hairline = CGFloat(1) // the app's `border`, not iDenfy's 2pt
	private static let rowHeight = CGFloat(56) // matches the `large` button height

	@MainActor
	private static func applyCornerRadii() {
		IdenfyButtonsUISettingsV2.idenfyButtonCorderRadius = pill
		IdenfyButtonsUISettingsV2.idenfyChooseAnotherPhotoButtonCornerRadius = pill

		// Cards and panels.
		IdenfyPrivacyPolicyViewUISettingsV2.idenfyPrivacyPolicyCardBorderRadius = cardRadius
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewDetailsCardCornerRadius = cardRadius
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewDetailsCardCornerRadius = cardRadius
		IdenfyInstructionAlertUISettigsV2.idenfyInstructionAlertDetailsCardCornerRadius = cardRadius
		IdenfyLoadingHUDUISettingsV2.idenfyLoadingHUDCornerRadius = cardRadius

		// The "Méthode de vérification" chips and the country field are ~45pt tall
		// controls, same as a button — pill, not card radius.
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewItemSelectionCornerRadius = pill
		IdenfyIssuedCountryViewUISettingsV2.idenfyIssuedCountryViewCountryViewCorderRadius = pill
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarCorderRadius = pill

		// List panels stay on the card radius — they are tall surfaces.
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCornerRadius = cardRadius
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCornerRadius = cardRadius
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCornerRadius = cardRadius

		// Captured-photo preview and the cropping frame.
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewPhotoCornerRadius = cardRadius
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewCroppingViewCornerRadius = cardRadius
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewCroppingRectangleCornerRadius = cardRadius
	}

	// Secondary "retake / choose another" buttons — the whole family, so the four
	// screens stay consistent. iDenfy ships a white fill with a thin coloured
	// border; we use the app's grey `secondary` button instead (the same one our
	// cancel actions use), so gold stays reserved for accents.
	@MainActor
	private static func applySecondaryButtons() {
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewRetakePhotoButtonBackgroundColor = secondaryFill
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewRetakePhotoButtonBorderColor = secondaryFill
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewRetakePhotoButtonTextColor = text
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewRetakePdfButtonBackgroundColor = secondaryFill
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewRetakePdfButtonBorderColor = secondaryFill
		IdenfyPdfResultViewUISettingsV2.idenfyPdfResultViewRetakePdfButtonTextColor = text
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewChooseAnotherPhotoButtonBackgroundColor = secondaryFill
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewChooseAnotherPhotoButtonBorderColor = secondaryFill
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewChooseAnotherPhotoButtonTextColor = text
		IdenfyFaceAuthenticationCommonUISettingsV2.idenfyFaceAuthenticationRetryAlertRetryButtonBackgroundColor = secondaryFill
		IdenfyFaceAuthenticationCommonUISettingsV2.idenfyFaceAuthenticationRetryAlertRetryButtonButtonBorderColor = secondaryFill
		IdenfyFaceAuthenticationCommonUISettingsV2.idenfyFaceAuthenticationRetryAlertRetryButtonTextColor = text
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
		settings.livenessReadyScreenButtonCornerRadius = Int32(pill)
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

	@MainActor
	private static func brandingLogo() -> UIImage? {
		karaImage("KaraBrandingLogo")
	}

	// Looks in the pod's resource bundle first, then the host/main bundle —
	// covers both static and dynamic framework linkage. The logo ships in the
	// pod; the background ships in the app's asset catalog (config plugin).
	@MainActor
	static func karaImage(_ name: String) -> UIImage? {
		let host = Bundle(for: KaraBundleToken.self)
		let bundles = [
			host.url(forResource: "KaraIdenfyResources", withExtension: "bundle")
				.flatMap(Bundle.init(url:)),
			host,
			Bundle.main,
		].compactMap { $0 }
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
		// Transparent: KaraIdenfyLayout slides the app's background image behind
		// every screen, and an opaque screen colour would hide it. `background`
		// stays the flat fallback for surfaces that must not be see-through.
		IdenfyCommonColors.idenfyBackgroundColorV2 = .clear
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
		// Splash spinner inherits idenfyBlackV2 (now light) → white. Gold instead.
		IdenfySplashScreenViewUISettingsV2.idenfySplashScreenViewSpinnerTintColor = gold
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
		// Back arrow and close icon in the app's white, not gold.
		IdenfyToolbarUISettingsV2.idenfyDefaultToolbarBackIconTintColor = text
		IdenfyToolbarUISettingsV2.idenfyCameraPreviewSessionToolbarBackIconTintColor = text
		IdenfyToolbarUISettingsV2.idenfyLanguageSelectionToolbarCloseIconTintColor = text
		// The language globe defaulted to the main colour, so it was the one gold
		// icon among white ones.
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
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCellHighlightedTextColor = onButton
		// Document-capture onboarding screen ("Front of the ID card"). Its continue
		// button text was unset → white-on-white (invisible). Keep the button white,
		// force dark text in both states.
		IdenfyStaticCameraOnBoardingViewUISettingsV2.idenfyCameraOnBoardingEnabledContinueButtonTextColor = onButton
		IdenfyStaticCameraOnBoardingViewUISettingsV2.idenfyCameraOnBoardingDisabledContinueButtonTextColor = onButton
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
		// End-of-flow and permission screens. Same white-on-white trap, and these
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

	// Disabled primary buttons. iDenfy's default is a white@20% block with
	// white@50% text — heavier than ours, which is a transparent pill with a
	// white/20 border. No border knob here, so: lighter fill, dimmer label.
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

	// Spinners default to white. On the white primary buttons that is invisible;
	// everywhere else (dark cards, dark lists) gold matches the app's loaders.
	@MainActor
	private static func applySpinners() {
		IdenfyPrivacyPolicyViewUISettingsV2.idenfyPrivacyPolicyAgreeButtonLoadingSpinnerTintColor = onButton
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewContinueButtonLoadingSpinnerTintColor = onButton
		IdenfyQuestionnaireViewUISettingsV2.idenfyQuestionnaireViewContinueButtonLoadingSpinnerTintColor = onButton
		IdenfyCountryAndDocumentSelectionViewUISettingsV2.idenfyCountryAndDocumentSelectionViewCountryLoadingSpinnerTintColor = gold
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryLoadingSpinnerTintColor = gold
		IdenfyLoadingHUDUISettingsV2.idenfyLoadingSpinnerTintColor = gold
	}

	// Status tints. Every "light" colour below is a light-mode pastel (#FFEBEE,
	// #FFF3E0, #E8F5E9, ...) that renders as a glaring near-white block on our
	// background — the blur/glare and auto-capture-failure cards use them. Swap
	// for 12% washes of the app's semantic colours, the way our own cards do it.
	@MainActor
	private static func applyStatusTints() {
		IdenfyCommonColors.idenfyErrorLightRedColorV2 = error.withAlphaComponent(0.12)
		IdenfyCommonColors.idenfyWarningLightYellowV2 = warning.withAlphaComponent(0.12)
		IdenfyCommonColors.idenfyBackgroundGreenV2 = success.withAlphaComponent(0.12)
		IdenfyCommonColors.idenfyLightBlueColor = info.withAlphaComponent(0.12)
		IdenfyCommonColors.idenfyWarningYellowV2 = warning
		IdenfyCommonColors.idenfyBlueColor = info
		IdenfyCommonColors.idenfyBorderGreenV2 = success
		IdenfyCommonColors.idenfyFaceDetectedColor = success
		IdenfyCommonColors.idenfyFaceNotDetectedColor = disabledText
		// iDenfy purple survives in a few highlight states. Fold it into gold.
		IdenfyCommonColors.idenfyPurpleV2 = gold
		IdenfyCommonColors.idenfyPurpleTextV2 = onButton
		IdenfyCommonColors.idenfyBackgroundPurpleV2 = gold
	}

	// 2pt borders everywhere; the app uses 1pt at ~12% white. Row heights go to
	// 56 to match our large control height (the document list already ships 56).
	@MainActor
	private static func applyBordersAndRowHeights() {
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewBorderWidth = hairline
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCellBorderWidth = hairline
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewBorderColor = border
		IdenfyDocumentSelectionViewUISettingsV2.idenfyDocumentSelectionViewDocumentTableViewCellBorderColor = border
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountrySearchBarBorderWidth = hairline
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewBorderWidth = hairline
		IdenfyCountrySelectionViewUISettingsV2.idenfyCountrySelectionViewCountryTableViewCellBorderWidth = hairline
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewBorderWidth = hairline
		IdenfyLanguageSelectionViewUISettingsV2.idenfyLanguageSelectionViewLanguageTableViewCellBorderWidth = hairline
		IdenfyIssuedCountryViewUISettingsV2.idenfyIssuedCountryViewCountryViewBorderWidth = hairline
		IdenfyUploadPhotoViewUISettingsV2.idenfyUploadPhotoViewCroppingViewBorderWidth = hairline
		IdenfyPhotoResultViewUISettingsV2.idenfyPhotoResultViewPhotoBorderWidth = hairline

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
