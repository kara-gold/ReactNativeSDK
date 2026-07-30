import Foundation
import UIKit
import idenfyviews

//  Layout corrections the iDenfy settings API does not expose.
//
//  We already instantiate the SDK's UINavigationController ourselves, so we can
//  sit on it as a delegate and adjust each screen right after it appears. This
//  is deliberately preferred over IdenfyViewsBuilderV2 subclassing for these
//  three fixes: it depends on UIKit types and on the SDK's public view surface,
//  never on its internal constraint graph, so an SDK bump can only make it stop
//  matching. It degrades to a no-op, never to a broken layout.
//
//  ponytail: heuristic, by design. Anything structural (rebuilding a screen's
//  content) belongs in a proper IdenfyViewsBuilderV2 subclass instead.
@MainActor
final class KaraIdenfyLayout: NSObject, UINavigationControllerDelegate {
	// Matches the app's `large` Button (minHeight 56).
	private static let buttonHeight = CGFloat(56)
	// Below this width a UIButton is an icon or an inline link, not a CTA.
	private static let ctaMinimumWidth = CGFloat(200)

	// The SDK's navigation controller only holds a weak delegate reference.
	static let shared = KaraIdenfyLayout()

	func navigationController(
		_: UINavigationController,
		didShow viewController: UIViewController,
		animated _: Bool
	) {
		let root = viewController.view
		normalize(root)
		// The SDK lays some screens out after the transition completes; a second
		// pass on the next runloop tick catches those without any observation.
		DispatchQueue.main.async { [weak root] in
			guard let root else { return }
			self.normalize(root)
		}
	}

	private func normalize(_ view: UIView?) {
		guard let view else { return }

		if let scrollView = view as? UIScrollView {
			scrollView.showsVerticalScrollIndicator = false
			scrollView.showsHorizontalScrollIndicator = false
		}

		if let button = view as? UIButton {
			resize(button)
		}

		// Typed pass. `CountryAndDocumentSelectionView` exposes its subviews, so
		// the document chips can be centred without guessing which table it is:
		// the country picker's rows must stay left-aligned behind their flag.
		if let selection = view as? CountryAndDocumentSelectionView {
			centerCells(in: selection.documentTableView)
			centerCells(in: selection.digitalIdTableView)
		}

		for subview in view.subviews {
			normalize(subview)
		}
	}

	// Buttons carry their own height constraint. Editing its constant keeps the
	// SDK's layout consistent; adding a competing constraint would not.
	private func resize(_ button: UIButton) {
		guard
			button.bounds.width >= Self.ctaMinimumWidth,
			button.title(for: .normal)?.isEmpty == false
		else { return }

		button.contentHorizontalAlignment = .center
		button.titleLabel?.textAlignment = .center

		for constraint in button.constraints
		where constraint.firstAttribute == .height && constraint.relation == .equal {
			if constraint.constant != Self.buttonHeight {
				constraint.constant = Self.buttonHeight
			}
		}
	}

	// ponytail: only the cells on screen. The document chips all fit, so there is
	// nothing to scroll into view; wire a cell-injection view if that stops being
	// true.
	private func centerCells(in tableView: UITableView) {
		for cell in tableView.visibleCells {
			centerLabels(in: cell.contentView)
		}
	}

	private func centerLabels(in view: UIView) {
		if let label = view as? UILabel {
			label.textAlignment = .center
		}
		for subview in view.subviews {
			centerLabels(in: subview)
		}
	}
}
