package com.idenfyreactnative.domain

import com.idenfy.idenfySdk.CoreSdkInitialization.IdenfyUserFlowHandler
import com.idenfy.idenfySdk.api.logging.IdenfyLoggingHandlerUseCase

/**
 * Captures what happens INSIDE the iDenfy flow.
 *
 * The RN wrapper only ever surfaces the terminal result, so everything between
 * "SDK opened" and "SDK closed" is a black box - the same blind spot the hosted
 * WebView had, and the reason we cannot tell where users abandon. iDenfy exposes
 * two native hooks for this and neither is bridged:
 *
 *  - [IdenfyLoggingHandlerUseCase] - the firehose. Screen tags crossed with
 *    interactions (see EventNameEnum: STEP_VIEW, CONTINUE_CLICK, BACK_CLICK,
 *    CANCEL_CLICK, CAPTURE_CLICK, RETAKE_CLICK, CAMERA_START...). These strings
 *    are NOT documented and differ between platforms and SDK versions - send them
 *    raw and group them at analysis time, never type them.
 *  - [IdenfyUserFlowHandler] - the semantic events (document/country chosen,
 *    photo uploaded per step, processing started).
 *
 * Entries are emitted live via [onEvent] AND accumulated. The live channel is
 * what survives a mid-flow app kill (the promise never resolves then, so the
 * batch would be lost with the process); the accumulated copy still rides back
 * on the promise so a listener that failed to attach costs nothing.
 */
internal class KaraIdenfyTrace : IdenfyLoggingHandlerUseCase, IdenfyUserFlowHandler {

    /** Called on every entry, from whichever thread iDenfy used. Set by the bridge module. */
    var onEvent: ((String) -> Unit)? = null

    private val entries = mutableListOf<String>()
    private val lock = Any()

    private fun append(line: String) {
        // iDenfy calls these from its own threads, so the list needs a lock. The
        // bridge emit stays outside it: it hops to the JS thread on its own and
        // must not hold the lock while doing so.
        synchronized(lock) { entries.add(line) }
        onEvent?.invoke(line)
    }

    /** Newline-joined so it fits the `WritableMap` string contract untouched. */
    fun dump(): String = synchronized(lock) { entries.joinToString("\n") }

    /**
     * Both handlers are registered on SDK-wide statics, so one instance serves
     * every verification of the process and the accumulated copy has to be
     * cleared when a new flow starts - otherwise a second verification would
     * report the first one's entries too. iOS gets this for free by building a
     * fresh instance on each start().
     */
    fun reset() {
        synchronized(lock) { entries.clear() }
    }

    // IdenfyLoggingHandlerUseCase

    override fun logEvent(event: String, message: String, token: String) {
        // `token` is the session authToken - deliberately dropped, it must not
        // reach the JS logs.
        append("log|$event|$message")
    }

    // IdenfyUserFlowHandler

    override fun onDocumentSelected(documentType: String) {
        append("flow|documentSelected|$documentType")
    }

    override fun onCountrySelected(issuingCountryCode: String) {
        append("flow|countrySelected|$issuingCountryCode")
    }

    override fun onPhotoUploaded(photo: String, step: String) {
        // `photo` is the image payload - only the step name is useful here.
        append("flow|photoUploaded|$step")
    }

    /**
     * Android-only hook, iOS has no plural counterpart: it fires once when the
     * whole set is in. Emitted under its own name rather than folded into
     * photoUploaded, so a trace stays honest about which platform produced it.
     */
    override fun onPhotosUploaded(photosUploaded: Boolean) {
        append("flow|photosUploaded|$photosUploaded")
    }

    override fun onProcessingStarted(processingStarted: Boolean) {
        append("flow|processingStarted|$processingStarted")
    }
}
