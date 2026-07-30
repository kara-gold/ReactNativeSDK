import Foundation
import iDenfySDK
import idenfycore
import UIKit
@objc(IdenfyReactNative)
class IdenfyReactNative: RCTEventEmitter {

    // Held strongly: IdenfyController does not retain the handlers, and a
    // deallocated trace silently stops recording mid-flow.
    private var trace: KaraIdenfyTrace?

    private static let traceEvent = "onIdenfyEvent"
    private var hasListeners = false
    // The first entries (SplashScreen|ViewDidLoad) fire microseconds after
    // start(); if JS has not finished subscribing yet, RN drops them silently.
    // Buffer until startObserving(), then replay in order.
    private var pending: [String] = []

    override func supportedEvents() -> [String]! { [Self.traceEvent] }

    override func startObserving() {
        hasListeners = true
        for line in pending { sendEvent(withName: Self.traceEvent, body: line) }
        pending.removeAll()
    }

    override func stopObserving() { hasListeners = false }

    private func emit(_ line: String) {
        guard hasListeners else {
            pending.append(line)
            return
        }
        sendEvent(withName: Self.traceEvent, body: line)
    }
    
    @objc(start:withResolver:withRejecter:)
    func start(_ config: NSDictionary,
               resolve:@escaping RCTPromiseResolveBlock,reject:@escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.run(withConfig: config, resolver: resolve, rejecter: reject)
        }
    }
    
    @objc(startFaceReAuth:withResolver:withRejecter:)
    func startFaceReAuth(_ config: NSDictionary,
                         resolve: @escaping RCTPromiseResolveBlock,
                         reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.runFaceReauth(withConfig: config, resolver: resolve, rejecter: reject)
        }
    }
    
  @MainActor private func run(withConfig config: NSDictionary,
                     resolver resolve: @escaping RCTPromiseResolveBlock,
                     rejecter reject: @escaping RCTPromiseRejectBlock) {
        do {
            KaraIdenfyTheme.apply()
            let authToken = GetSdkConfig.getAuthToken(config: config)
            let idenfySettingsV2 = GetSdkConfig.getIdenfySettingsFromConfig(config: config, authToken: authToken)
            SdkVersionManager.platformWrapper = "reactnative"
            let idenfyController = IdenfyController.shared
            let trace = KaraIdenfyTrace()
            trace.onEvent = { [weak self] line in self?.emit(line) }
            self.trace = trace
            idenfyController.setIdenfyLoggingHandler(idenfyLoggingHandler: trace)
            idenfyController.setIdenfyUserFlowCallbacksHandler(idenfyUserFlowHandler: trace)
            idenfyController.initializeIdenfySDKV2WithManual(
              idenfySettingsV2: idenfySettingsV2,
              idenfyViewsV2: GetSdkConfig.getIdenfyViews()
            )

            let idenfyVC = idenfyController.instantiateNavigationController()
            idenfyVC.delegate = KaraIdenfyLayout.shared
            
            idenfyVC.modalPresentationStyle = .fullScreen
            
            UIApplication.shared.windows.first?.rootViewController?.present(idenfyVC, animated: true)
            
            handleSdkCallbacks(idenfyController: idenfyController, resolver: resolve)
            
        } catch let error as NSError {
            reject("error", error.domain, error)
            return
        } catch {
            reject("error", "Unexpected error. Verify that config is structured correctly.", error)
            return
        }
    }
    
    private func handleSdkCallbacks(idenfyController: IdenfyController, resolver resolve: @escaping RCTPromiseResolveBlock) {
        idenfyController.handleIdenfyCallbacksWithManualResults(idenfyIdentificationResult: {
            [weak self] idenfyIdentificationResult
            in
            var response = NativeResponseToReactNativeResponseMapper.map(o: idenfyIdentificationResult)
            response["karaTrace"] = self?.trace?.dump() ?? ""
            resolve(response)
        })
    }
    
  @MainActor private func runFaceReauth(withConfig config: NSDictionary,
                               resolver resolve: @escaping RCTPromiseResolveBlock,
                               rejecter reject: @escaping RCTPromiseRejectBlock) {
        do {
            // Must run here too. Every *UISettingsV2 property is a lazy static that
            // caches on first read, so a face re-auth started before any other
            // iDenfy entry point would freeze the whole SDK on its own defaults
            // for the rest of the process.
            KaraIdenfyTheme.apply()
            let authToken = GetSdkConfig.getAuthToken(config: config)
            let immediateRedirect = GetSdkConfig.getImmediateRedirectFromConfig(config: config)
            let idenfyFaceAuthUISettings = GetSdkConfig.getFaceAuthSettingsFromConfig(config: config)
            SdkVersionManager.platformWrapper = "reactnative"
            let idenfyController = IdenfyController.shared
            let faceReauthenticationInitialization = FaceAuthenticationInitialization(authenticationToken: authToken, withImmediateRedirect: immediateRedirect, idenfyFaceAuthUISettings: idenfyFaceAuthUISettings)
            idenfyController.initializeFaceAuthentication(faceAuthenticationInitialization: faceReauthenticationInitialization)
            
            let idenfyVC = idenfyController.instantiateNavigationController()
            idenfyVC.delegate = KaraIdenfyLayout.shared
            
            idenfyVC.modalPresentationStyle = .fullScreen
            
            UIApplication.shared.windows.first?.rootViewController?.present(idenfyVC, animated: true)
            
            handleFaceReauthSdkCallbacks(idenfyController: idenfyController, resolver: resolve)
            
        } catch let error as NSError {
            reject("error", error.domain, error)
            return
        } catch {
            reject("error", "Unexpected error. Verify that config is structured correctly.", error)
            return
        }
    }
    
    private func handleFaceReauthSdkCallbacks(idenfyController: IdenfyController, resolver resolve: @escaping RCTPromiseResolveBlock) {
        idenfyController.handleIdenfyCallbacksForFaceAuthentication(faceAuthenticationResult: {
            faceAuthenticationResult
            in
            let response = NativeResponseToReactNativeResponseMapper.mapFaceReauth(o: faceAuthenticationResult)
            resolve(response)
        })
    }

    @objc(startRequestUpdate:withResolver:withRejecter:)
    func startRequestUpdate(_ config: NSDictionary,
                            resolve: @escaping RCTPromiseResolveBlock,
                            reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.runRequestUpdate(withConfig: config, resolver: resolve, rejecter: reject)
        }
    }

    @MainActor private func runRequestUpdate(withConfig config: NSDictionary,
                                             resolver resolve: @escaping RCTPromiseResolveBlock,
                                             rejecter reject: @escaping RCTPromiseRejectBlock) {
        do {
            KaraIdenfyTheme.apply()
            let authToken = GetSdkConfig.getAuthToken(config: config)
            let idenfySettingsV2 = GetSdkConfig.getIdenfySettingsFromConfig(config: config, authToken: authToken)
            SdkVersionManager.platformWrapper = "reactnative"
            let idenfyController = IdenfyController.shared
            idenfyController.initializeIdenfySDKV2WithManual(
              idenfySettingsV2: idenfySettingsV2,
              idenfyViewsV2: GetSdkConfig.getIdenfyViews()
            )

            let idenfyVC = idenfyController.instantiateNavigationController()
            idenfyVC.delegate = KaraIdenfyLayout.shared

            idenfyVC.modalPresentationStyle = .fullScreen

            UIApplication.shared.windows.first?.rootViewController?.present(idenfyVC, animated: true)

            handleRequestUpdateSdkCallbacks(idenfyController: idenfyController, resolver: resolve)

        } catch let error as NSError {
            reject("error", error.domain, error)
            return
        } catch {
            reject("error", "Unexpected error. Verify that config is structured correctly.", error)
            return
        }
    }

    private func handleRequestUpdateSdkCallbacks(idenfyController: IdenfyController, resolver resolve: @escaping RCTPromiseResolveBlock) {
        idenfyController.handleIdenfyCallbacksForRequestUpdate(requestUpdateResult: {
            informationUpdateStatus
            in
            let response = NativeResponseToReactNativeResponseMapper.mapRequestUpdate(o: informationUpdateStatus)
            resolve(response)
        })
    }
}
