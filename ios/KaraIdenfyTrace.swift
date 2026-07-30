import Foundation
import iDenfySDK

/// Captures what happens INSIDE the iDenfy flow.
///
/// The RN wrapper only ever surfaces the terminal result, so everything between
/// "SDK opened" and "SDK closed" is a black box — the same blind spot the hosted
/// WebView had. iDenfy exposes two native hooks for this and neither is bridged:
///
///  - `IdenfyLoggingHandlerUseCase` — the firehose. Crosses ~36 screen tags
///    (SPLASHSCREEN, COUNTRYSELECTION, DOCUMENTSELECTION, ONBOARDING,
///    CAMERASESSION, UPLOADSESSION, LEAVINGSDK, ERROREVENT…) with ~12 interactions
///    (STEP_VIEW, CONTINUE_CLICK, BACK_CLICK, CAPTURE_CLICK, RETAKE_CLICK…).
///    Those values are NOT documented; they were read out of the Android AAR and
///    may change between SDK versions — never type them strictly on the JS side.
///  - `IdenfyUserFlowHandler` — the semantic events (document/country chosen,
///    photo uploaded per step, processing started).
///
/// Entries are accumulated and returned with the promise rather than streamed:
/// turning this module into an RCTEventEmitter would mean touching the ObjC
/// bridge header and the New Architecture codegen, for no gain — the flow is
/// short and the full sequence at close is what we actually want to read.
@objc final class KaraIdenfyTrace: NSObject, IdenfyLoggingHandlerUseCase,
	IdenfyUserFlowHandler
{
	private var entries: [String] = []
	private let lock = NSLock()

	private func append(_ line: String) {
		lock.lock()
		defer { lock.unlock() }
		entries.append(line)
	}

	/// Newline-joined so it fits `RNResponse` ([String: String]) untouched.
	func dump() -> String {
		lock.lock()
		defer { lock.unlock() }
		return entries.joined(separator: "\n")
	}

	// MARK: - IdenfyLoggingHandlerUseCase

	@objc func logEvent(event: String, message: String, token: String) {
		// `token` is the session authToken — deliberately dropped, it must not
		// reach the JS logs.
		append("log|\(event)|\(message)")
	}

	// MARK: - IdenfyUserFlowHandler

	@objc func onDocumentSelected(documentType: String) {
		append("flow|documentSelected|\(documentType)")
	}

	@objc func onCountrySelected(issuingCountryCode: String) {
		append("flow|countrySelected|\(issuingCountryCode)")
	}

	@objc func onPhotoUploaded(photo: String, step: String) {
		// `photo` is the image payload — only the step name is useful here.
		append("flow|photoUploaded|\(step)")
	}

	@objc func onProcessingStarted(processingStarted: Bool) {
		append("flow|processingStarted|\(processingStarted)")
	}
}
