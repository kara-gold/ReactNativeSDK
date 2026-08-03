package com.idenfyreactnative.di

import com.idenfyreactnative.data.IdenfyReactNativeCallbacksStoreImpl
import com.idenfyreactnative.domain.IdenfyReactNativeCallbacksUseCase
import com.idenfyreactnative.domain.IdenfySdkActivityEventListener
import com.idenfyreactnative.domain.KaraIdenfyTrace
import com.idenfyreactnative.domain.mappers.NativeResponseToReactNativeResponseMapper

internal class DIProvider {
    val idenfySdkActivityEventListener: IdenfySdkActivityEventListener by lazy {
        IdenfySdkActivityEventListener(idenfyReactNativeCallbacksUseCase, nativeResponseToReactNativeResponseMapper, karaIdenfyTrace)
    }
    val idenfyReactNativeCallbacksUseCase by lazy {
        IdenfyReactNativeCallbacksUseCase(idenfyReactNativeCallbacksStore)
    }

    // Shared by the module (registers it with the SDK, forwards its lines to JS)
    // and by the activity result listener (attaches the dump to the terminal result).
    val karaIdenfyTrace by lazy {
        KaraIdenfyTrace()
    }

    private val nativeResponseToReactNativeResponseMapper by lazy {
        NativeResponseToReactNativeResponseMapper()
    }

    private val idenfyReactNativeCallbacksStore by lazy {
        IdenfyReactNativeCallbacksStoreImpl()
    }
}
