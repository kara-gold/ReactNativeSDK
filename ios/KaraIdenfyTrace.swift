import Foundation
import iDenfySDK

/// Captures what happens INSIDE the iDenfy flow.
///
/// The RN wrapper only ever surfaces the terminal result, so everything between
/// "SDK opened" and "SDK closed" is a black box — the same blind spot the hosted
/// WebView had, and the reason we cannot tell where users abandon. iDenfy exposes
/// two native hooks for this and neither is bridged:
///
///  - `IdenfyLoggingHandlerUseCase` — the firehose. Screen tags (SplashScreen,
///    CountryAndDocumentSelection, OnBoarding, CameraSession, UploadSession,
///    LeavingSDK, ErrorEvent, NetworkRequest…) crossed with interactions
///    (viewDidLoad, continueButtonPressed, takePhotoPressed, backButtonAction…).
///    These strings are NOT documented and differ between platforms and SDK
///    versions — send them raw and group them at analysis time, never type them.
///  - `IdenfyUserFlowHandler` — the semantic events (document/country chosen,
///    photo uploaded per step, processing started).
///
/// Entries are emitted live via `onEvent` AND accumulated. The live channel is
/// what survives a mid-flow app kill (the promise never resolves then, so the
/// batch would be lost with the process); the accumulated copy still rides back
/// on the promise so a listener that failed to attach costs nothing.
@objc final class KaraIdenfyTrace: NSObject, IdenfyLoggingHandlerUseCase,
	IdenfyUserFlowHandler
{
	/// Called on every entry, on the main queue. Set by the bridge module.
	var onEvent: ((String) -> Void)?

	private var entries: [String] = []
	private let lock = NSLock()

	private func append(_ line: String) {
		lock.lock()
		entries.append(line)
		lock.unlock()
		// iDenfy calls these from its own queues; RCTEventEmitter is not
		// thread-safe, so hop to main before crossing the bridge.
		DispatchQueue.main.async { [onEvent] in onEvent?(line) }
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
