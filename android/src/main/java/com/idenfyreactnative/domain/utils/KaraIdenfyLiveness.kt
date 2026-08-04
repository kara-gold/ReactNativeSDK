package com.idenfyreactnative.domain.utils

import android.content.Context
import android.graphics.Typeface
import com.facetec.sdk.FaceTecCustomization
import com.facetec.sdk.FaceTecFeedbackCustomization
import com.facetec.sdk.FaceTecFrameCustomization
import com.facetec.sdk.FaceTecGuidanceCustomization
import com.facetec.sdk.FaceTecOvalCustomization
import com.facetec.sdk.FaceTecOverlayCustomization
import com.facetec.sdk.FaceTecResultScreenCustomization
import com.idenfy.idenfySdk.api.liveliness.IdenfyLivenessUISettings
import com.idenfyreactnative.R

/**
 * Kara dark + gold theme for the FaceTec liveness (face scan) screens.
 *
 * Mirrors the palette in ios/IdenfyKaraTheme.swift. Two of its values are
 * deliberately NOT mirrored, because the decompiled Android mapping shows they
 * would render invisible text here; both are called out at the property below.
 *
 * ## Why this goes through livenessCustomUISettings and not the individual fields
 *
 * IdenfyLivenessUISettings exposes ~38 individual properties, and setting them
 * here would be dead code. P1.a.a (LivenessCustomizationUtils, decompiled from
 * sdk-api 9.1.0) is what builds the FaceTecCustomization, and it OVERWRITES every
 * one of those 38 fields from R.color/R.drawable before FaceTec ever sees them:
 *
 *     settings.livenessReadyScreenBackgroundColor =
 *         ContextCompat.getColor(ctx, R.color.idenfyLivenessBackgroundColor)   // unconditional
 *
 * The one field it does not overwrite is livenessCustomUISettings. When that is
 * non-null the method returns it verbatim on its first branch and skips the whole
 * default pass, so it is the only hook that survives:
 *
 *     if (settings?.livenessCustomUISettings != null) return settings.livenessCustomUISettings
 *
 * ## Why the resource route cannot do this job
 *
 * That default pass drives the entire palette from four colour resources, and two
 * of them are load-bearing in incompatible ways:
 *
 *   - idenfyFaceCameraPreviewSessionLivenessAccentColor (gold, for us) feeds the
 *     oval progress AND the feedback bar background AND the ready-screen button
 *     fill AND the ready-screen text plate. One value cannot be both our accent
 *     and three surfaces behind text.
 *   - the result screen's background is never mapped at all, so it keeps
 *     FaceTecResultScreenCustomization's default of -1 (opaque white) while its
 *     foreground comes from idenfySecondColorV2 (#FAFAFA): white on white.
 *
 * ## Safety of the object graph
 *
 * FaceTecCustomization implements neither Parcelable nor Serializable, and
 * IdenfyLivenessUISettings.writeToParcel writes 30 fields that do not include it
 * (nor any of the Typefaces). That is survivable only because the settings never
 * cross a Parcel: IdenfyController.initializeIdenfySDKV2WithManual stores the
 * IdenfySettingsV2 on a singleton field and launches the activity with a bare
 * Intent, no extras. If a future SDK version starts passing settings through the
 * Intent, this object is dropped silently and the theme reverts to the resource
 * pass. Nothing crashes; it just stops applying.
 */
internal object KaraIdenfyLiveness {

	private const val BACKGROUND = 0xFF090710.toInt()
	private const val GOLD = 0xFFE1BE6B.toInt()
	private const val FOREGROUND = 0xFFFAFAFA.toInt()
	private const val ON_LIGHT = 0xFF090710.toInt()
	private const val BUTTON_FILL = 0xFFFAFAFA.toInt()
	private const val ERROR = 0xFFEF4444.toInt()
	private const val TRANSPARENT = 0x00000000

	/**
	 * Opaque, unlike the translucent card iOS uses for the same surface. Every one
	 * of these sits over the live camera feed, where a 5% white wash leaves the
	 * text on the video. Same call, and same reason, as idenfyLightGrayColor in
	 * res/values/colors.xml.
	 */
	private const val OVER_CAMERA = 0xFF1C1C1E.toInt()

	private const val DISABLED_FILL = 0x1FFFFFFF
	private const val DISABLED_TEXT = 0x66FFFFFF
	private const val TRACK = 0x1FFFFFFF

	/** `rounded-2xl` for plates, a pill for the CTA. */
	private const val PLATE_RADIUS = 16
	private const val BUTTON_RADIUS = 24

	/**
	 * @param context only needed for the fonts, which are read from the app's
	 *   assets. Everything else is pure data. When it is null the colours still
	 *   apply and FaceTec keeps its own typeface.
	 */
	fun settings(context: Context?): IdenfyLivenessUISettings =
		IdenfyLivenessUISettings().apply {
			livenessCustomUISettings = customization(context)
		}

	private fun customization(context: Context?): FaceTecCustomization {
		// The SDK ships these under HK Grotesk's filenames; our module overrides the
		// asset itself, so the bytes are Gabarito. Same trick as res/font.
		val bold = font(context, "hkgrotesk_bold.ttf")
		val regular = font(context, "hkgrotesk_regular.ttf")

		val guidance = FaceTecGuidanceCustomization().apply {
			backgroundColors = BACKGROUND
			foregroundColor = FOREGROUND
			// iOS sets this to the dark on-button colour. Not mirrored: on Android
			// this single value feeds foregroundColor, readyScreenHeaderTextColor and
			// readyScreenSubtextTextColor, all of which sit on the dark background
			// above, so the dark value would make the ready screen unreadable.
			readyScreenHeaderTextColor = FOREGROUND
			readyScreenSubtextTextColor = FOREGROUND
			retryScreenHeaderTextColor = FOREGROUND
			retryScreenSubtextTextColor = FOREGROUND
			// No plate behind the ready-screen copy; the background already carries it.
			readyScreenTextBackgroundColor = TRANSPARENT
			readyScreenTextBackgroundCornerRadius = PLATE_RADIUS

			// The app's primary button. This is the pairing the resource route can
			// never express: iDenfy exposes no button-label colour, so on that path
			// the label stays FaceTec's hardcoded white (-1) and any light fill makes
			// it vanish. Owning the FaceTecCustomization is what lets the fill be
			// white and the label dark, as everywhere else in the flow.
			buttonBackgroundNormalColor = BUTTON_FILL
			buttonTextNormalColor = ON_LIGHT
			buttonBackgroundHighlightColor = GOLD
			buttonTextHighlightColor = ON_LIGHT
			buttonBackgroundDisabledColor = DISABLED_FILL
			buttonTextDisabledColor = DISABLED_TEXT
			buttonBorderColor = TRANSPARENT
			buttonBorderWidth = 0
			buttonCornerRadius = BUTTON_RADIUS

			retryScreenImageBorderColor = GOLD
			retryScreenOvalStrokeColor = GOLD

			headerFont = bold
			subtextFont = regular
			readyScreenHeaderFont = bold
			readyScreenSubtextFont = regular
			buttonFont = bold
		}

		val oval = FaceTecOvalCustomization().apply {
			strokeColor = GOLD
			strokeWidth = 2
			progressColor1 = GOLD
			progressColor2 = GOLD
			progressRadialOffset = 6
		}

		val frame = FaceTecFrameCustomization().apply {
			backgroundColor = BACKGROUND
			// Borderless: the frame is the full-bleed session container, and a visible
			// edge around it reads as a modal inside a modal.
			borderColor = BACKGROUND
			borderWidth = 0
			cornerRadius = 0
		}

		val feedback = FaceTecFeedbackCustomization().apply {
			backgroundColors = OVER_CAMERA
			textColor = FOREGROUND
			cornerRadius = PLATE_RADIUS
			textFont = bold
		}

		val result = FaceTecResultScreenCustomization().apply {
			// FaceTec defaults this to -1, opaque white, and iDenfy never maps it.
			// This is the single line that stops the upload/result screen being a
			// white sheet carrying near-white text in the middle of a dark flow.
			backgroundColors = BACKGROUND
			foregroundColor = FOREGROUND
			activityIndicatorColor = GOLD
			showUploadProgressBar = true
			uploadProgressFillColor = GOLD
			uploadProgressTrackColor = TRACK
			resultAnimationBackgroundColor = BACKGROUND
			resultAnimationForegroundColor = GOLD
			resultAnimationUnsuccessBackgroundColor = BACKGROUND
			resultAnimationUnsuccessForegroundColor = ERROR
			sessionAbortAnimationBackgroundColor = BACKGROUND
			sessionAbortAnimationForegroundColor = FOREGROUND
			messageFont = bold
		}

		val overlay = FaceTecOverlayCustomization().apply {
			backgroundColor = BACKGROUND
			// FaceTec always draws something here; left off it falls back to its own
			// placeholder. Points at the SDK's branding asset, which this module
			// already overrides with a light recolour.
			brandingImage = R.drawable.idenfy_ic_liveliness_overlay_branding_image_v2
			showBrandingImage = true
		}

		return FaceTecCustomization().apply {
			guidanceCustomization = guidance
			ovalCustomization = oval
			frameCustomization = frame
			feedbackCustomization = feedback
			resultScreenCustomization = result
			overlayCustomization = overlay
		}
	}

	// Asset lookup is a system boundary and a missing font must not take down a
	// verification: FaceTec's own typeface is a fine fallback.
	private fun font(context: Context?, asset: String): Typeface? =
		context?.let {
			runCatching { Typeface.createFromAsset(it.assets, "fonts/$asset") }.getOrNull()
		}
}
