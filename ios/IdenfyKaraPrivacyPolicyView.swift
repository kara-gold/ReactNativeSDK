import Foundation
import UIKit
import idenfyviews

//  The privacy screen, restructured into "verify your identity in 3 steps".
//
//  iDenfy ships three collapsible sections: data protection, process, and
//  compliance. Kara only wants the process one, expanded, with each step as its
//  own card. Nothing here is rebuilt: `PrivacyPolicyViewV2` is an `open class`
//  whose subviews are all `public var`, so we subclass and restyle. The SDK
//  keeps ownership of the content, the wiring and the button actions.
//
//  Injected through `IdenfyViewsBuilderV2.withPrivacyPolicyView`, which is the
//  supported route. If a future SDK version changes the section layout, the
//  worst case is that the steps stop looking like cards.
@MainActor
final class KaraIdenfyPrivacyPolicyView: PrivacyPolicyViewV2 {
	private static let cardBackground = UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
	private static let cardRadius = CGFloat(16)
	private static let cardSpacing = CGFloat(12)
	private static let cardInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

	private var restyled = false

	override func layoutSubviews() {
		super.layoutSubviews()
		// The SDK populates the sections after init; wait for a real layout pass.
		guard !restyled, bounds.width > 0 else { return }
		restyled = true
		restyle()
	}

	private func restyle() {
		scrollView.showsVerticalScrollIndicator = false

		// Only the steps remain. The data-protection and compliance copy moves to
		// the app's own KYC intro screen.
		dataProtectionStackView.isHidden = true
		complianceStackView.isHidden = true

		// De-accordion the remaining section: no header, always expanded.
		processHeaderView.isHidden = true
		processContentView.isHidden = false
		processStackView.backgroundColor = .clear
		processStackView.layer.cornerRadius = 0

		processContentView.spacing = Self.cardSpacing
		for step in processContentView.arrangedSubviews {
			makeCard(step)
		}
	}

	private func makeCard(_ view: UIView) {
		view.backgroundColor = Self.cardBackground
		view.layer.cornerRadius = Self.cardRadius
		view.layer.masksToBounds = true
		// Padding without touching the SDK's constraints: only a stack view can be
		// inset from the outside. Rows that are not stacks keep their own spacing.
		if let stack = view as? UIStackView {
			stack.isLayoutMarginsRelativeArrangement = true
			stack.directionalLayoutMargins = Self.cardInsets
		}
	}
}
