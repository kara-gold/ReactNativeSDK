package com.idenfyreactnative.domain.utils

import android.content.Context
import android.graphics.Typeface
import com.facetec.sdk.FaceTecCancelButtonCustomization
import com.facetec.sdk.FaceTecCustomization
import com.facetec.sdk.FaceTecFeedbackCustomization
import com.facetec.sdk.FaceTecFrameCustomization
import com.facetec.sdk.FaceTecGuidanceCustomization
import com.facetec.sdk.FaceTecOvalCustomization
import com.facetec.sdk.FaceTecOverlayCustomization
import com.facetec.sdk.FaceTecResultScreenCustomization
import com.facetec.sdk.FaceTecSDK
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
 *
 * ## Low-light mode and the light variant
 *
 * FaceTec measures ambient light and, in low light, turns the screen into a
 * fill light for the face: its sanitizer (ey.a(int) in the repackaged 7.0.3)
 * forces every session background to opaque white, and no API disables that.
 * Text, button and oval colours are NOT sanitized: the selector (ey.a()) reads
 * them from the customization registered via FaceTecSDK.setLowLightCustomization
 * when one exists, else from the normal customization. iDenfy never registers
 * one, so before lowLight() below a dark room meant near-white text and button
 * on the forced white background. settings() registers the light variant so
 * both modes stay legible.
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

	/** For the low-light variant, where the sanitizer forces this anyway. */
	private const val WHITE = 0xFFFFFFFF.toInt()
	private const val LIGHT_DISABLED_FILL = 0x14090710
	private const val LIGHT_DISABLED_TEXT = 0x66090710
	private const val LIGHT_TRACK = 0x1F090710

	/** `rounded-2xl` for plates, a pill for the CTA. */
	private const val PLATE_RADIUS = 16
	private const val BUTTON_RADIUS = 24

	/**
	 * @param context only needed for the fonts, which are read from the app's
	 *   assets. Everything else is pure data. When it is null the colours still
	 *   apply and FaceTec keeps its own typeface.
	 */
	fun settings(context: Context?): IdenfyLivenessUISettings {
		// Static on FaceTec, set once; nothing in the SDK writes it afterwards
		// (verified in the 7.0.3 bytecode). Without it, low-light mode keeps the
		// dark variant's near-white text on its forced white background.
		FaceTecSDK.setLowLightCustomization(lowLight(context))
		return IdenfyLivenessUISettings().apply {
			livenessCustomUISettings = customization(context)
		}
	}

	private fun customization(context: Context?): FaceTecCustomization {
		// The SDK ships these under HK Grotesk's filenames; our module overrides the
		// asset itself, so the bytes are Gabarito. Same trick as res/font.
		val bold = font(context, "hkgrotesk_bold.ttf")
		val regular = font(context, "hkgrotesk_regular.ttf")

		val guidance = FaceTecGuidanceCustomization().apply {
			// Honoured in normal light. The white background an earlier Pixel 9a test
			// observed was not this field being ignored: the test ran in a dark room,
			// where FaceTec's low-light sanitizer forces every session background to
			// opaque white regardless of any customization. Legibility in that mode
			// comes from the lowLight() variant, not from this field.
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
			// A dark plate behind the ready-screen copy. In normal light it blends into
			// the identical background; kept so the copy stays legible whichever colour
			// ends up behind it. The low-light variant drops it: dark text sits
			// directly on the forced white there.
			readyScreenTextBackgroundColor = BACKGROUND
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

		val frame = FaceTecFrameCustomization().apply {
			backgroundColor = BACKGROUND
			// Borderless: the frame is the full-bleed session container, and a visible
			// edge around it reads as a modal inside a modal.
			borderColor = BACKGROUND
			borderWidth = 0
			cornerRadius = 0
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
			// Off, not recoloured. The device photo shows this mark rendering, which is
			// how we know the overlay customization is honoured, but the asset is the
			// iDenfy wordmark and we have no Kara vector in this module to put in its
			// place. Hiding it beats shipping someone else's brand in our KYC flow.
			showBrandingImage = false
		}

		// FaceTec's own X, drawn in its blue, is what the device showed: taking the
		// escape hatch skips iDenfy's livenessCancelButtonImage wiring, so nothing was
		// pointing this at an asset of ours.
		val cancel = FaceTecCancelButtonCustomization().apply {
			customImage = R.drawable.idenfy_ic_liveliness_camera_session_cancel_image_v2
		}

		return FaceTecCustomization().apply {
			guidanceCustomization = guidance
			ovalCustomization = oval()
			frameCustomization = frame
			feedbackCustomization = feedback(bold)
			resultScreenCustomization = result
			overlayCustomization = overlay
			cancelButtonCustomization = cancel
		}
	}

	/**
	 * The variant FaceTec switches to in low ambient light, where its sanitizer
	 * forces every session background to opaque white so the screen can light the
	 * face. Designed for that forced white: dark text, inverted button, no text
	 * plate. Oval and feedback are shared with the dark variant; the feedback bar
	 * sits over the camera feed, not over the white.
	 */
	private fun lowLight(context: Context?): FaceTecCustomization {
		val bold = font(context, "hkgrotesk_bold.ttf")
		val regular = font(context, "hkgrotesk_regular.ttf")

		val guidance = FaceTecGuidanceCustomization().apply {
			foregroundColor = ON_LIGHT
			readyScreenHeaderTextColor = ON_LIGHT
			readyScreenSubtextTextColor = ON_LIGHT
			retryScreenHeaderTextColor = ON_LIGHT
			retryScreenSubtextTextColor = ON_LIGHT
			// No plate: dark text sits directly on the forced white.
			readyScreenTextBackgroundColor = TRANSPARENT

			// The dark variant's button, inverted: dark fill, light label.
			buttonBackgroundNormalColor = BACKGROUND
			buttonTextNormalColor = FOREGROUND
			buttonBackgroundHighlightColor = GOLD
			buttonTextHighlightColor = ON_LIGHT
			buttonBackgroundDisabledColor = LIGHT_DISABLED_FILL
			buttonTextDisabledColor = LIGHT_DISABLED_TEXT
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

		val frame = FaceTecFrameCustomization().apply {
			// The sanitizer forces this to white anyway; set for coherence.
			backgroundColor = WHITE
			borderColor = WHITE
			borderWidth = 0
			cornerRadius = 0
		}

		val result = FaceTecResultScreenCustomization().apply {
			backgroundColors = WHITE
			foregroundColor = ON_LIGHT
			activityIndicatorColor = GOLD
			showUploadProgressBar = true
			uploadProgressFillColor = GOLD
			uploadProgressTrackColor = LIGHT_TRACK
			resultAnimationBackgroundColor = WHITE
			resultAnimationForegroundColor = GOLD
			resultAnimationUnsuccessBackgroundColor = WHITE
			resultAnimationUnsuccessForegroundColor = ERROR
			sessionAbortAnimationBackgroundColor = WHITE
			sessionAbortAnimationForegroundColor = ON_LIGHT
			messageFont = bold
		}

		val overlay = FaceTecOverlayCustomization().apply {
			backgroundColor = WHITE
			showBrandingImage = false
		}

		// Not the shared idenfy_ic_liveliness_camera_session_cancel_image_v2
		// override: that X is near-white and vanishes on the forced white.
		val cancel = FaceTecCancelButtonCustomization().apply {
			customImage = R.drawable.kara_ft_cancel_dark
		}

		return FaceTecCustomization().apply {
			guidanceCustomization = guidance
			ovalCustomization = oval()
			frameCustomization = frame
			feedbackCustomization = feedback(bold)
			resultScreenCustomization = result
			overlayCustomization = overlay
			cancelButtonCustomization = cancel
		}
	}

	private fun oval(): FaceTecOvalCustomization =
		FaceTecOvalCustomization().apply {
			strokeColor = GOLD
			strokeWidth = 2
			progressColor1 = GOLD
			progressColor2 = GOLD
			progressRadialOffset = 6
		}

	private fun feedback(bold: Typeface?): FaceTecFeedbackCustomization =
		FaceTecFeedbackCustomization().apply {
			backgroundColors = OVER_CAMERA
			textColor = FOREGROUND
			cornerRadius = PLATE_RADIUS
			textFont = bold
		}

	// Asset lookup is a system boundary and a missing font must not take down a
	// verification: FaceTec's own typeface is a fine fallback.
	private fun font(context: Context?, asset: String): Typeface? =
		context?.let {
			runCatching { Typeface.createFromAsset(it.assets, "fonts/$asset") }.getOrNull()
		}
}
