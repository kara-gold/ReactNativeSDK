import Foundation

//  Copy handed over from React Native at start().
//
//  It lives in the app's i18n JSON rather than in our Idenfy.strings tables so
//  it ships over the air: the .lproj files are baked into the bundle, so
//  changing a word there costs a native build and a store release. This is
//  regulatory copy that will move, so it must not.
enum KaraIdenfyCopy {
	nonisolated(unsafe) static var proofOfAddressInstructions: String?

	static func read(from config: NSDictionary) {
		let value = config["karaProofOfAddressInstructions"] as? String
		proofOfAddressInstructions = (value?.isEmpty == false) ? value : nil
	}
}
