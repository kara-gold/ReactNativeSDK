import Foundation
import UIKit
import idenfyviews

//  The retake alerts ("the document is too blurry", "part of the data is
//  covered") keep iDenfy's gold-on-outline button while every other secondary
//  button in the flow is grey.
//
//  Neither of our two usual levers reaches them. `IdenfyRetakeAlert` exposes no
//  UISettings class at all, and it is a `Modal`: the SDK adds it over a screen
//  that is already on stage, so the navigation delegate — which only fires on
//  push — never walks it. There is no `withRetakeAlert` hook on the views
//  builder either.
//
//  So the class's own `layoutSubviews` is the hook. It is the one call site
//  guaranteed to run for a view about to be shown, whoever presents it and
//  whenever.
//
//  ponytail: swizzling, deliberately. Delete this the day iDenfy ships either a
//  settings class or a builder hook for the alert.
@MainActor
enum KaraIdenfyRetakeAlert {
	private static var originalLayoutSubviews: IMP?

	static func install() {
		guard originalLayoutSubviews == nil else { return }

		let cls: AnyClass = IdenfyRetakeAlert.self
		let selector = #selector(UIView.layoutSubviews)
		guard let method = class_getInstanceMethod(cls, selector) else { return }

		let replacement: @convention(block) (UIView) -> Void = { view in
			if let original = originalLayoutSubviews {
				let callSuper = unsafeBitCast(
					original, to: (@convention(c) (UIView, Selector) -> Void).self
				)
				callSuper(view, selector)
			}
			guard let alert = view as? IdenfyRetakeAlert else { return }
			KaraIdenfyTheme.styleSecondaryButton(alert.retakeButton)
		}

		let implementation = imp_implementationWithBlock(replacement)
		// The alert may not override layoutSubviews, in which case `method` is
		// UIView's and swapping its implementation would hit every view in the app.
		// Adding the override first keeps the change on this one class, and the
		// implementation we captured is then the inherited one — our super call.
		if class_addMethod(cls, selector, implementation, method_getTypeEncoding(method)) {
			originalLayoutSubviews = method_getImplementation(method)
		} else {
			originalLayoutSubviews = method_setImplementation(method, implementation)
		}
	}
}
