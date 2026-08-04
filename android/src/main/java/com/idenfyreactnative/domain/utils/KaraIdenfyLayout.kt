package com.idenfyreactnative.domain.utils

import android.app.Activity
import android.app.Application
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.DialogFragment
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager
import com.idenfyreactnative.R

/**
 * The two screen-level corrections the iDenfy settings API does not expose on
 * Android: the app's background image behind every screen, and our own title in
 * the toolbar in place of the iDenfy wordmark.
 *
 * Android counterpart of ios/IdenfyKaraLayout.swift, and deliberately the same
 * shape: hook the SDK's own lifecycle, match on what the theme already painted,
 * and edit the view tree just after it is built. It depends on the framework and
 * on resource names, never on the SDK's internal layout structure, so an SDK bump
 * can only make it stop matching. It degrades to a no-op, never to a broken
 * screen.
 *
 * ## Why not a window background
 *
 * The obvious Android route is `android:windowBackground` on IdenfyThemeV2, which
 * IdenfyMainActivity applies itself (`setTheme(R.style.IdenfyThemeV2)` on entry).
 * It cannot work here. The activity's content view is idenfy_activity_main_v2,
 * whose first child is a static `<include>` of the whole document-selection
 * screen, painted opaque with idenfyDocumentSelectionViewBackgroundColor and
 * never removed: every fragment is added to the CoordinatorLayout *around* it.
 * Nothing behind the content view is ever visible, so a window background would
 * be dead pixels.
 *
 * Making the screen colours transparent instead, so the window shows through,
 * fails on the same structure from the other side. Decompiling
 * ObserveNavigationLiveDataUseCase (sdk-api 9.1.0) shows the SDK reaches for
 * `FragmentTransaction.add` as often as `replace`, and the two capture-result
 * screens are among the added ones:
 *
 *     Z/U -> add(idenfy_coordinatorlayout_main_fragments_container,
 *                I/d, "DOCUMENT_PHOTO_RESULT_FRAGMENT")
 *     Z/r0 -> add(idenfy_coordinatorlayout_main_fragments_container,
 *                Q/c, "FACE_CAMERA_RESULT_FRAGMENT")
 *
 * `add` leaves the fragment underneath in place, so the camera is still mounted
 * and running behind the photo you just took. A transparent result screen would
 * show the live camera straight through it, which is exactly the bug iOS shipped
 * and reverted (see the comment on insertBackground in IdenfyKaraLayout.swift).
 *
 * So the backdrop goes INSIDE each screen: an opaque image at index 0 of that
 * screen's own root. Every screen stays as opaque as the SDK built it, and
 * whatever is mounted below stays hidden.
 *
 * ## What is covered and what is not
 *
 * A screen is painted when its root carries [backgroundToken], the colour
 * idenfyBackgroundColorV2 resolves to in res/values/colors.xml. That is the
 * theme's own background token, so matching on it reaches every screen the theme
 * repainted and nothing else, without enumerating fragment classes.
 *
 * The camera surfaces are excluded by that same rule, twice over. The three
 * camera fragment layouts put no background on their root at all, so the match
 * fails before anything is inserted; and the preview itself is painted with
 * idenfyDocumentCameraPreviewSessionBackgroundColor, which resolves to idenfyBlack
 * (#000000) because colors.xml deliberately leaves that root alone. Neither the
 * viewfinder nor the FaceTec liveness screen can be reached from here.
 *
 * FaceTec is excluded structurally as well: [THEMED_ACTIVITIES] is an allow-list
 * of the two activities iDenfy declares, so com.facetec.sdk.FaceTecSessionActivity
 * (a separate activity of our process, themed through Theme.AppCompat.Translucent
 * and customised in KaraIdenfyLiveness) is never even walked. So is our own React
 * activity.
 *
 * Dialogs are skipped too. Their cards resolve to the same background token, and
 * a full-screen photo cropped into a small card reads as noise. So are the two
 * Compose-hosted screens, which the SDK paints from inside the composition; see
 * [hostsCompose].
 */
object KaraIdenfyLayout : Application.ActivityLifecycleCallbacks {
	// The only activities iDenfy declares in its manifest, both themed
	// IdenfyThemeV2. An allow-list rather than a FaceTec deny-list, so a future
	// activity in our process cannot be repainted by accident.
	private val THEMED_ACTIVITIES = setOf(
		"com.idenfy.idenfySdk.core.presentation.view.IdenfyMainActivity",
		"com.idenfy.idenfySdk.faceauthentication.view.FaceAuthenticationActivity",
	)

	private const val BACKDROP_TAG = "kara_idenfy_backdrop"
	private const val TITLE_TAG = "kara_idenfy_toolbar_title"

	@Volatile
	private var installed = false

	/**
	 * Registered once, from the React module's constructor. Both callbacks below
	 * are no-ops until an iDenfy activity is created, so this costs one set
	 * lookup per activity in the app.
	 */
	@JvmStatic
	fun install(application: Application) {
		if (installed) return
		synchronized(this) {
			if (installed) return
			installed = true
			application.registerActivityLifecycleCallbacks(this)
		}
	}

	override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
		if (activity.javaClass.name !in THEMED_ACTIVITIES) return

		// The activity's own content, which onCreate has already inflated by the
		// time this runs. This is the static document-selection include described
		// above; it is the only screen that is not a fragment.
		activity.findViewById<View>(android.R.id.content)?.let { paint(it) }

		// Every other screen. Recursive, so the child managers the questionnaire
		// and country pickers use are covered by the same registration.
		(activity as? FragmentActivity)
			?.supportFragmentManager
			?.registerFragmentLifecycleCallbacks(FragmentPainter, true)
	}

	override fun onActivityStarted(activity: Activity) = Unit
	override fun onActivityResumed(activity: Activity) = Unit
	override fun onActivityPaused(activity: Activity) = Unit
	override fun onActivityStopped(activity: Activity) = Unit
	override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit
	override fun onActivityDestroyed(activity: Activity) = Unit

	private object FragmentPainter : FragmentManager.FragmentLifecycleCallbacks() {
		override fun onFragmentViewCreated(
			fm: FragmentManager,
			fragment: Fragment,
			view: View,
			savedInstanceState: Bundle?,
		) {
			// A dialog is a card, not a screen: it carries the same background
			// token and would get the photo cropped into it.
			if (fragment is DialogFragment) return
			paint(view)
		}
	}

	/**
	 * Walks one screen. The toolbar pass is independent of the backdrop pass, so
	 * the screens that keep their flat background still get the title.
	 */
	private fun paint(root: View) {
		findThemed(root)?.let { screen ->
			if (!hostsCompose(screen)) {
				insertBackdrop(screen)
				clearTokenBackgrounds(screen)
			}
		}
		setToolbarTitle(root)
	}

	/**
	 * Two screens, the suspected-results one and the manual-review waiting one, are
	 * a toolbar plus a ComposeView pinned below it. Their body is painted from
	 * inside the composition:
	 *
	 *     Modifier.fillMaxWidth()
	 *             .background(colorResource(R.color.idenfyBackgroundColorV2))
	 *
	 * (IdentificationSuspectedResultsComposableBase and
	 * ManualReviewingIdentificationResultsStatusWaitingComposableBase, decompiled
	 * from sdk-api 9.1.0). That is a draw modifier on a composition node, not a
	 * View background, so nothing this class does can reach it, and the colour it
	 * reads is the token itself, shared with ~100 other names including every
	 * dialog card, so it cannot be made transparent either.
	 *
	 * A backdrop here would therefore be visible in the toolbar strip and painted
	 * over everywhere below it, leaving a hard edge at the toolbar. Skipping keeps
	 * these two screens exactly as they are today, flat and correctly themed. That
	 * is the honest outcome until iDenfy paints that surface from a colour name of
	 * its own instead of the global token.
	 *
	 * Matched on the class name so the module needs no Compose dependency. A screen
	 * iDenfy migrates to Compose later falls back to today's flat background rather
	 * than to a seam.
	 */
	private fun hostsCompose(view: View): Boolean {
		if (view.javaClass.name.startsWith("androidx.compose.ui.platform.ComposeView")) {
			return true
		}
		if (view !is ViewGroup) return false
		for (index in 0 until view.childCount) {
			if (hostsCompose(view.getChildAt(index))) return true
		}
		return false
	}

	/**
	 * The outermost view the theme painted with the background token. Stops at the
	 * first match: on a fragment that is the fragment root, on the activity content
	 * it is the included screen one level down.
	 */
	private fun findThemed(view: View): ViewGroup? {
		if (view is ViewGroup && view.isBackgroundToken()) return view
		if (view !is ViewGroup) return null
		for (index in 0 until view.childCount) {
			findThemed(view.getChildAt(index))?.let { return it }
		}
		return null
	}

	/**
	 * The screen keeps painting opaque, the image just does it instead of the flat
	 * colour. Nothing mounted below can show through, which is the whole point.
	 */
	private fun insertBackdrop(screen: ViewGroup) {
		if (screen.getChildAt(0)?.tag == BACKDROP_TAG) return

		val backdrop = LayoutInflater.from(screen.context)
			.inflate(R.layout.kara_idenfy_backdrop, screen, false)
		backdrop.tag = BACKDROP_TAG
		screen.addView(backdrop, 0)
		screen.background = null
	}

	/**
	 * App bars, list backgrounds and panels the theme also painted with the token.
	 * Left alone they would sit on the image as flat slabs. Clearing them is safe
	 * by construction: the only thing behind them is the backdrop this same pass
	 * just inserted.
	 */
	private fun clearTokenBackgrounds(parent: ViewGroup) {
		for (index in 0 until parent.childCount) {
			val child = parent.getChildAt(index)
			if (child.tag != BACKDROP_TAG && child.isBackgroundToken()) {
				child.background = null
			}
			if (child is ViewGroup) clearTokenBackgrounds(child)
		}
	}

	/**
	 * The toolbar centre is an ImageView of the iDenfy wordmark and the SDK offers
	 * no way to put a word there. Hide it and drop a real label on its constraints:
	 * actual text in the app's font, localised through our own string table, not a
	 * picture of text.
	 *
	 * Hiding it is durable. sdk-api 9.1.0 touches this id from exactly two places,
	 * BaseFragmentV2.a and BaseDialogFragmentV2.setupIdenfyLogo, and both return
	 * immediately unless PartnerInfo.environment is FREEMIUM; neither ever sets a
	 * visibility. Every other appearance of the id is in layout XML.
	 *
	 * Where the SDK ships the logo already gone, over the viewfinder and over the
	 * capture result, we add nothing: a bare toolbar there is its intent, and iOS
	 * reads the same.
	 */
	private fun setToolbarTitle(root: View) {
		val logo = root.findViewById<View>(
			com.idenfySdk.R.id.idenfy_imageview_common_idenfylogo
		) ?: return
		if (logo.visibility != View.VISIBLE) return

		val bar = logo.parent as? ViewGroup ?: return
		if (bar.findViewWithTag<View>(TITLE_TAG) != null) return

		logo.visibility = View.GONE
		val title = LayoutInflater.from(bar.context)
			.inflate(R.layout.kara_idenfy_toolbar_title, bar, false)
		title.tag = TITLE_TAG
		bar.addView(title)
	}

	/**
	 * Read from the merged resources rather than hardcoded, so it tracks
	 * res/values/colors.xml and cannot drift from the theme it is supposed to
	 * match.
	 */
	private fun View.isBackgroundToken(): Boolean {
		val background = this.background as? ColorDrawable ?: return false
		return background.color == context.getColor(R.color.idenfyBackgroundColorV2)
	}
}
