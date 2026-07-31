import Foundation
import UIKit
import idenfyviews

//  Screens whose secondary button neither the theme nor the layout pass reaches.
//
//  `IdenfyRetakeAlert` exposes no UISettings class at all and is a `Modal`: the
//  SDK adds it over a screen that is already on stage, so the navigation
//  delegate — which only fires on push — never walks it. `PdfResultViewV2` does
//  take our colours from the settings API, but it gets no navigation callback
//  either, so the label repaint that has to happen at runtime never ran on it.
//
//  Their own `layoutSubviews` is the hook. It is the one call site guaranteed to
//  run for a view about to be shown, whoever presents it and whenever, and it
//  keeps working if the SDK repaints the label after we do.
//
//  ponytail: swizzling, deliberately. Injecting the views through the builder
//  would work for the ones that have a hook, but the SDK deep-copies injected
//  views through NSKeyedArchiver, which has already cost us one process abort.
//  Delete this the day iDenfy paints these labels from its own text settings.
@MainActor
enum KaraIdenfySecondaryButtons {
	private static var originals: [ObjectIdentifier: IMP] = [:]

	static func install() {
		patch(IdenfyRetakeAlert.self) { ($0 as? IdenfyRetakeAlert)?.retakeButton }
		patch(PdfResultViewV2.self) { ($0 as? PdfResultViewV2)?.chooseAnotherFileButton }
	}

	private static func patch(_ cls: UIView.Type, button: @escaping (UIView) -> UIButton?) {
		let key = ObjectIdentifier(cls)
		guard originals[key] == nil else { return }

		let selector = #selector(UIView.layoutSubviews)
		guard let method = class_getInstanceMethod(cls, selector) else { return }

		let replacement: @convention(block) (UIView) -> Void = { view in
			// Keyed on the class we patched, not on the view's own class: a subclass
			// would otherwise miss its entry and skip the original implementation.
			if let original = originals[key] {
				let callSuper = unsafeBitCast(
					original, to: (@convention(c) (UIView, Selector) -> Void).self
				)
				callSuper(view, selector)
			}
			guard let button = button(view) else { return }
			KaraIdenfyTheme.styleSecondaryButton(button)
		}

		let implementation = imp_implementationWithBlock(replacement)
		// The class may not override layoutSubviews, in which case `method` is
		// UIView's and swapping its implementation would hit every view in the app.
		// Adding the override first keeps the change on this one class, and the
		// implementation we captured is then the inherited one — our super call.
		if class_addMethod(cls, selector, implementation, method_getTypeEncoding(method)) {
			originals[key] = method_getImplementation(method)
		} else {
			originals[key] = method_setImplementation(method, implementation)
		}
	}
}
