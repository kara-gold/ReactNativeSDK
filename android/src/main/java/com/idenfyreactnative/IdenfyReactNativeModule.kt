package com.idenfyreactnative

import com.facebook.react.bridge.*
import com.idenfy.idenfySdk.CoreSdkInitialization.IdenfyController
import com.idenfy.idenfySdk.CoreSdkInitialization.IdenfyUserFlowController
import com.idenfy.idenfySdk.api.initialization.IdenfySettingsV2.IdenfyBuilderV2
import com.idenfy.idenfySdk.faceauthentication.api.FaceAuthenticationInitialization
import com.idenfyreactnative.di.DIProvider
import com.idenfyreactnative.domain.IdenfyReactNativeCallbacksUseCase
import com.idenfyreactnative.domain.IdenfySdkActivityEventListener
import com.idenfyreactnative.domain.KaraIdenfyTrace
import com.idenfyreactnative.domain.utils.GetSdkDataFromConfig

class IdenfyReactNativeModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {
  private val diProvider = DIProvider()
  private val idenfyReactNativeCallbacksUseCase: IdenfyReactNativeCallbacksUseCase
  private val idenfySdkActivityEventListener: IdenfySdkActivityEventListener
  private val karaIdenfyTrace: KaraIdenfyTrace

  // Trace lines produced while nothing is subscribed. The first entries fire
  // microseconds after start() and RCTDeviceEventEmitter silently drops events
  // nobody listens to, so they are held here and replayed on addListener().
  private val pendingTraceLines = mutableListOf<String>()
  private var traceListenerCount = 0
  private val traceLock = Any()

  init {
    idenfyReactNativeCallbacksUseCase = diProvider.idenfyReactNativeCallbacksUseCase
    idenfySdkActivityEventListener = diProvider.idenfySdkActivityEventListener
    karaIdenfyTrace = diProvider.karaIdenfyTrace
    karaIdenfyTrace.onEvent = { line -> emitTraceLine(line) }
    reactContext.addActivityEventListener(idenfySdkActivityEventListener)
  }

  override fun getName(): String {
    return "IdenfyReactNative"
  }

  /**
   * Called by `new NativeEventEmitter(NativeModules.IdenfyReactNative)` on the JS
   * side - the same subscription iOS requires, so the listener is identical on
   * both platforms. Note that a bare `DeviceEventEmitter.addListener()` never
   * reaches a native module: it would still receive the lines emitted after it
   * subscribed, but nothing would ever replay the buffered ones.
   */
  @ReactMethod
  fun addListener(eventName: String) {
    if (eventName != TRACE_EVENT) return

    val replay = synchronized(traceLock) {
      traceListenerCount += 1
      val buffered = pendingTraceLines.toList()
      pendingTraceLines.clear()
      buffered
    }
    replay.forEach { reactApplicationContext.emitDeviceEvent(TRACE_EVENT, it) }
  }

  @ReactMethod
  fun removeListeners(count: Int) {
    synchronized(traceLock) {
      traceListenerCount = (traceListenerCount - count).coerceAtLeast(0)
    }
  }

  private fun emitTraceLine(line: String) {
    synchronized(traceLock) {
      // No subscriber yet, or no live JS runtime to receive it: hold the line.
      // It is in the accumulated dump either way, this only decides whether the
      // live channel gets it now or on the next subscription.
      if (traceListenerCount == 0 || !reactApplicationContext.hasActiveReactInstance()) {
        pendingTraceLines.add(line)
        return
      }
    }
    // Safe from the iDenfy threads that produce the lines: emitDeviceEvent hops
    // to the JS thread itself.
    reactApplicationContext.emitDeviceEvent(TRACE_EVENT, line)
  }

  // Example method
  // See https://reactnative.dev/docs/native-modules-android
  @ReactMethod
  fun multiply(a: Int, b: Int, promise: Promise) {
    promise.resolve(a * b)
  }

  @ReactMethod
  fun start(config: ReadableMap, promise: Promise) {
    idenfyReactNativeCallbacksUseCase.setCallbacksReceiver(promise)

    val currentActivity = getCurrentActivity()

    if (currentActivity == null) {
      idenfyReactNativeCallbacksUseCase.getCallbackReceiver()
        ?.reject("error", Exception("Android activity does not exist"))
      idenfyReactNativeCallbacksUseCase.resetPromise()
      return
    }

    try {

      val authToken = GetSdkDataFromConfig.getSdkTokenFromConfig(config)
      val idenfySettingsV2 = GetSdkDataFromConfig.getIdenfySettingsFromConfig(config)
      idenfySettingsV2.authToken = authToken

      // Drop the previous verification's entries, then (re)register. Both
      // handlers live on SDK-wide statics that outlive the flow, so registering
      // again is a no-op after the first start - the reset is what matters.
      karaIdenfyTrace.reset()
      IdenfyController.getInstance().setIdenfyLoggingHandler(karaIdenfyTrace)
      IdenfyUserFlowController.setIdenfyUserFlowHandler(karaIdenfyTrace)

      IdenfyController.getInstance().initializeIdenfySDKV2WithManual(
        currentActivity,
        IdenfyController.IDENFY_REQUEST_CODE,
        idenfySettingsV2
      )
    }

    //Unexpected exceptions
    catch (e: Throwable) {
      e.printStackTrace()
      idenfyReactNativeCallbacksUseCase.getCallbackReceiver()?.reject(
        "error",
        Exception("Unexpected error. Verify that config is structured correctly.")
      )
      idenfyReactNativeCallbacksUseCase.resetPromise()
      return
    }

  }

  @ReactMethod
  fun startRequestUpdate(config: ReadableMap, promise: Promise) {
    idenfyReactNativeCallbacksUseCase.setCallbacksReceiver(promise)

    val currentActivity = getCurrentActivity()

    if (currentActivity == null) {
      idenfyReactNativeCallbacksUseCase.getCallbackReceiver()
        ?.reject("error", Exception("Android activity does not exist"))
      idenfyReactNativeCallbacksUseCase.resetPromise()
      return
    }

    try {

      val authToken = GetSdkDataFromConfig.getSdkTokenFromConfig(config)
      val idenfySettingsV2 = GetSdkDataFromConfig.getIdenfySettingsFromConfig(config)
      idenfySettingsV2.authToken = authToken

      IdenfyController.getInstance().initializeIdenfySDKV2WithManual(
        currentActivity,
        IdenfyController.IDENFY_REQUEST_CODE,
        idenfySettingsV2
      )
    }

    //Unexpected exceptions
    catch (e: Throwable) {
      e.printStackTrace()
      idenfyReactNativeCallbacksUseCase.getCallbackReceiver()?.reject(
        "error",
        Exception("Unexpected error. Verify that config is structured correctly.")
      )
      idenfyReactNativeCallbacksUseCase.resetPromise()
      return
    }

  }

  @ReactMethod
  fun startFaceReAuth(config: ReadableMap, promise: Promise) {
    idenfyReactNativeCallbacksUseCase.setCallbacksReceiver(promise)

    val currentActivity = getCurrentActivity()

    if (currentActivity == null) {
      idenfyReactNativeCallbacksUseCase.getCallbackReceiver()
        ?.reject("error", Exception("Android activity does not exist"))
      idenfyReactNativeCallbacksUseCase.resetPromise()
      return
    }

    try {

      val authToken = GetSdkDataFromConfig.getSdkTokenFromConfig(config)
      val immediateRedirect = GetSdkDataFromConfig.getImmediateRedirectFromConfig(config)
      val faceAuthUISettings = GetSdkDataFromConfig.getFaceAuthSettingsFromConfig(config)
      val faceReauthenticationInitialization =
        FaceAuthenticationInitialization(authToken, immediateRedirect, faceAuthUISettings)
      IdenfyController.getInstance().initializeFaceAuthenticationSDKV2(
        currentActivity,
        IdenfyController.IDENFY_REQUEST_CODE,
        faceReauthenticationInitialization
      )
    }

    //Unexpected exceptions
    catch (e: Throwable) {
      e.printStackTrace()
      idenfyReactNativeCallbacksUseCase.getCallbackReceiver()?.reject(
        "error",
        Exception("Unexpected error. Verify that config is structured correctly.")
      )
      idenfyReactNativeCallbacksUseCase.resetPromise()
      return
    }

  }

  companion object {
    // Must stay in sync with the iOS bridge (IdenfyReactNative.swift) so one JS
    // listener serves both platforms.
    private const val TRACE_EVENT = "onIdenfyEvent"
  }

}
