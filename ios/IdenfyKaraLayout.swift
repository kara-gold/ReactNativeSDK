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
	// Room for the back button on one side and the language globe on the other.
	private static let titleSideInset = CGFloat(56)
	// The country field: taller than iDenfy's default, so it reads as a control.
	private static let fieldHeight = CGFloat(64)

	// The SDK's navigation controller only holds a weak delegate reference.
	static let shared = KaraIdenfyLayout()

	private static let backgroundTag = 0x4B41_5241 // "KARA"
	private static let titleTag = 0x4B59_4331 // "KYC1"
	// Our own key, in the partial Idenfy.strings tables the app already ships for
	// the four locales. iDenfy never looks it up.
	private static var title: String {
		Bundle.main.localizedString(forKey: "kara_toolbar_title", value: "", table: "Idenfy")
	}

	func navigationController(
		_ navigationController: UINavigationController,
		willShow viewController: UIViewController,
		animated _: Bool
	) {
		// Before the transition, so nothing appears one frame late: neither the
		// background image, nor the toolbar title (the iDenfy logo used to flash in
		// its place on the way to the language screen). Also on the container, so a
		// push never shows black between two screens.
		insertBackground(into: navigationController.view)
		insertBackground(into: viewController.view)
		normalize(viewController.view)
	}

	func navigationController(
		_: UINavigationController,
		didShow viewController: UIViewController,
		animated _: Bool
	) {
		let root = viewController.view
		insertBackground(into: root)
		normalize(root)
		// The SDK lays some screens out after the transition completes; a second
		// pass on the next runloop tick catches those without any observation.
		DispatchQueue.main.async { [weak root] in
			guard let root else { return }
			self.normalize(root)
		}
	}

	// The app paints every screen over assets/backgrounds/general-background.jpg.
	// A real image view, not a UIColor(patternImage:): the SDK deep-copies any
	// injected view through NSKeyedArchiver, and a pattern colour is not
	// encodable, so it aborted the process the moment a custom view was wired in
	// (crash 2026-07-30, -[UIColor encodeWithCoder:] under archivedDataWithRootObject:).
	// An image view is also a better fit anyway: real aspect-fill, no tiling seam
	// and no pattern-phase offset under the toolbar.
	private func insertBackground(into view: UIView?) {
		guard
			let view,
			view.viewWithTag(Self.backgroundTag) == nil,
			let image = KaraIdenfyTheme.karaImage("KaraIdenfyBackground")
		else { return }

		// The view stops painting its own colour only now that the image is behind
		// it. Transparency is never granted up front: the photo-result screen gets
		// no navigation callback, so a globally clear token showed the live camera
		// straight through it.
		view.backgroundColor = .clear

		let backdrop = UIImageView(image: image)
		backdrop.tag = Self.backgroundTag
		backdrop.contentMode = .scaleAspectFill
		backdrop.clipsToBounds = true
		backdrop.translatesAutoresizingMaskIntoConstraints = false
		view.insertSubview(backdrop, at: 0)
		NSLayoutConstraint.activate([
			backdrop.topAnchor.constraint(equalTo: view.topAnchor),
			backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
		])
	}

	private func normalize(_ view: UIView?) {
		guard let view else { return }

		// Any surface the theme painted with the background token becomes the app's
		// background image. Matching on the colour rather than on a view class
		// reaches every screen, including the ones we never get a callback for.
		if view.backgroundColor == KaraIdenfyTheme.background {
			insertBackground(into: view)
		}

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
			thicken(selection.countrySelectionInputView)
			pill(in: selection.documentTableView)
			pill(in: selection.digitalIdTableView)
		}

		// Every toolbar variant exposes a `logo` image view and no title label.
		switch view {
		case let bar as IdenfyToolbarV2WithLanguageSelection: setTitle(on: bar, logo: bar.logo)
		case let bar as IdenfyToolbarV2Default: setTitle(on: bar, logo: bar.logo)
		case let bar as IdenfyToolbarV2CloseButton: setTitle(on: bar, logo: bar.logo)
		case let bar as IdenfyCameraOnBoardingToolbarV2: setTitle(on: bar, logo: bar.logo)
		case let bar as IdenfyToolbarV2Questionnaire: setTitle(on: bar, logo: bar.logo)
		default: break
		}

		for subview in view.subviews {
			normalize(subview)
		}
	}

	// The toolbar centre is an image view, so the SDK offers no way to put a word
	// there. Hide it and drop a real label on its centre: actual text in the app's
	// font, not a picture of text, so it scales and stays crisp.
	private func setTitle(on bar: UIView, logo: UIImageView) {
		logo.isHidden = true
		guard bar.viewWithTag(Self.titleTag) == nil, let parent = logo.superview else {
			return
		}

		let title = Self.title
		guard !title.isEmpty, title != "kara_toolbar_title" else { return }

		// Matches the app's Header: `font-semibold text-kara-white text-xl`.
		let label = UILabel()
		label.tag = Self.titleTag
		label.text = title
		label.font = UIFont(name: ConstsIdenfyFonts.idenfyFontSemiBoldV2, size: 20)
		label.textColor = .white
		label.textAlignment = .center
		label.numberOfLines = 1
		// The back and language buttons sit either side; shrink rather than clip
		// when a locale runs long.
		label.adjustsFontSizeToFitWidth = true
		label.minimumScaleFactor = 0.7
		label.translatesAutoresizingMaskIntoConstraints = false
		parent.addSubview(label)
		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: logo.centerXAnchor),
			label.centerYAnchor.constraint(equalTo: logo.centerYAnchor),
			label.widthAnchor.constraint(
				lessThanOrEqualTo: bar.widthAnchor, constant: -Self.titleSideInset * 2
			),
		])
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

		// Derived from the height we just imposed, so it is always an exact pill.
		// The static `idenfyButtonCorderRadius` cannot be: it is one value for
		// buttons of several heights, and anything above half the height distorts
		// the corners. Sublayers carry the gradient fill and need it too.
		let radius = Self.buttonHeight / 2
		button.layer.cornerRadius = radius
		button.layer.masksToBounds = true
		for sublayer in button.layer.sublayers ?? [] where sublayer is CAGradientLayer {
			sublayer.cornerRadius = radius
		}
	}

	// The country field is a plain input the SDK sizes to its content. Give it the
	// app's control height so it reads as a field rather than a caption, and a
	// radius derived from that height so it stays a pill.
	private func thicken(_ field: UIView) {
		for constraint in field.constraints
		where constraint.firstAttribute == .height && constraint.relation == .equal {
			constraint.constant = Self.fieldHeight
		}
		field.layer.cornerRadius = Self.fieldHeight / 2
	}

	// Chips get the same treatment as the buttons: a radius derived from their own
	// height, so "as round as a button" holds whatever the row ends up measuring.
	// Only layers that are ALREADY rounded are touched, which is how we find the
	// chip's container without hardcoding a subview index.
	private func pill(in tableView: UITableView) {
		for cell in tableView.visibleCells {
			round(cell.contentView)
		}
	}

	private func round(_ view: UIView) {
		if view.layer.cornerRadius > 0, view.bounds.height > 0 {
			view.layer.cornerRadius = view.bounds.height / 2
		}
		for subview in view.subviews {
			round(subview)
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
