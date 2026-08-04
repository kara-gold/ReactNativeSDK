package com.idenfyreactnative.domain.utils

import com.facebook.react.bridge.ReadableMap
import com.idenfy.idenfySdk.api.ui.IdenfyFaceAuthUISettings
import com.idenfy.idenfySdk.api.initialization.IdenfySettingsV2
import com.idenfy.idenfySdk.api.models.DocumentCameraFrameVisibility
import com.idenfy.idenfySdk.api.models.IdenfyOnBoardingViewTypeEnum
import com.idenfy.idenfySdk.api.models.ImmediateRedirectEnum
import com.idenfy.idenfySdk.api.ui.IdenfyIdentificationResultsUISettingsV2
import com.idenfy.idenfySdk.api.ui.IdenfyUISettingsV2
import com.idenfy.idenfySdk.idenfycore.models.documentTypeData.DocumentTypeEnum
import com.idenfy.idenfySdk.CoreSdkInitialization.IdenfyLocaleEnum

internal object GetSdkDataFromConfig {
  fun getSdkTokenFromConfig(config: ReadableMap): String {
    return config.getString("authToken")!!
  }


  /**
   * @param context optional, and only used to load the liveness fonts from assets.
   *   Declared with a default so the existing call sites keep compiling untouched.
   *   Pass `currentActivity` from IdenfyReactNativeModule to switch the face-scan
   *   screens from FaceTec's typeface to Gabarito; every colour applies either way.
   */
  fun getIdenfySettingsFromConfig(
    config: ReadableMap,
    context: android.content.Context? = null
  ): IdenfySettingsV2 {
    val idenfySettings = IdenfySettingsV2()

    // Built up front and assigned unconditionally at the bottom of this function.
    // It used to be constructed inside the two `idenfySettings` / `idenfyUISettings`
    // config branches, and the Kara app calls start({ authToken }) with neither key,
    // so the whole block never ran: the settings object was never attached and the
    // liveness theme was silently dropped. Byte-for-byte the same bug that made
    // withLivenessUISettings dead on iOS, see ios/GetSdkConfig.swift.
    val idenfyUISettingsV2 = IdenfyUISettingsV2()
    idenfyUISettingsV2.idenfyLivenessUISettingsV2 = KaraIdenfyLiveness.settings(context)

    if (config.hasKey("idenfySettings") && !config.isNull("idenfySettings")) {
      val map = config.getMap("idenfySettings")!!

      if (map.hasKey("sslPinning") && !map.isNull("sslPinning")) {
        idenfySettings.sslPinning = map.getBoolean("sslPinning")
      }

      if (map.hasKey("selectedLocale") && !map.isNull("selectedLocale")) {
        val locale = map.getString("selectedLocale") ?: ""
        idenfySettings.selectedLocale = IdenfyLocaleEnum.valueOf(locale).locale
      }

      // `?.let` rather than `?: return`: an early return here would skip the
      // assignment at the bottom and put us straight back to an unthemed SDK.
      map.getMap("idenfyUISettings")?.takeIf { !map.isNull("idenfyUISettings") }?.let { uiSettingsMap ->

        if (uiSettingsMap.hasKey("isAdditionalSupportEnabled") && !uiSettingsMap.isNull("isAdditionalSupportEnabled")) {
          idenfyUISettingsV2.isAdditionalSupportEnabled =
            uiSettingsMap.getBoolean("isAdditionalSupportEnabled")
        }

        if (uiSettingsMap.hasKey("idenfyDocumentSelectionType") && !uiSettingsMap.isNull("idenfyDocumentSelectionType")) {
          val enum =
            uiSettingsMap.getString("idenfyDocumentSelectionType")?.camelToSnakeCase() ?: ""
          idenfyUISettingsV2.idenfyDocumentSelectionType =
            com.idenfy.idenfySdk.api.models.IdenfyDocumentSelectionTypeEnum.valueOf(enum)
        }

        if (uiSettingsMap.hasKey("idenfyOnBoardingViewType") && !uiSettingsMap.isNull("idenfyOnBoardingViewType")) {
          val enum = uiSettingsMap.getString("idenfyOnBoardingViewType")?.camelToSnakeCase() ?: ""
          idenfyUISettingsV2.idenfyOnBoardingViewTypeEnum =
            IdenfyOnBoardingViewTypeEnum.valueOf(enum)
        }

        if (uiSettingsMap.hasKey("isLanguageSelectionNeeded") && !uiSettingsMap.isNull("isLanguageSelectionNeeded")) {
          idenfyUISettingsV2.isLanguageSelectionNeeded =
            uiSettingsMap.getBoolean("isLanguageSelectionNeeded")
        }

        if (uiSettingsMap.hasKey("idenfyInstructionsEnum") && !uiSettingsMap.isNull("idenfyInstructionsEnum")) {
          val enum = uiSettingsMap.getString("idenfyInstructionsEnum")?.uppercase() ?: ""
          idenfyUISettingsV2.idenfyInstructionsType =
            com.idenfy.idenfySdk.camerasession.commoncamerasession.presentation.model.IdenfyInstructionsType.valueOf(
              enum
            )
        }

        // Same reason as above: no early return, or everything below is skipped.
        uiSettingsMap.getMap("idenfyIdentificationResultsUISettingsV2")
          ?.takeIf { !uiSettingsMap.isNull("idenfyIdentificationResultsUISettingsV2") }
          ?.let { resultsUISettingsMap ->
          val idenfyIdentificationResultsUISettingsV2 = IdenfyIdentificationResultsUISettingsV2()

          if (resultsUISettingsMap.hasKey("isShowErrorSpinnerImmediateRedirect") && !resultsUISettingsMap.isNull(
              "isShowErrorSpinnerImmediateRedirect"
            )
          ) {
            idenfyIdentificationResultsUISettingsV2.isShowErrorSpinnerImmediateRedirect =
              resultsUISettingsMap.getBoolean("isShowErrorSpinnerImmediateRedirect")
          }

          if (resultsUISettingsMap.hasKey("isAdditionalUploadingInformationVisible") && !resultsUISettingsMap.isNull(
              "isAdditionalUploadingInformationVisible"
            )
          ) {
            idenfyIdentificationResultsUISettingsV2.isAdditionalUploadingInformationVisible =
              resultsUISettingsMap.getBoolean("isAdditionalUploadingInformationVisible")
          }

          if (resultsUISettingsMap.hasKey("isShowSuccessSpinnerImmediateRedirect") && !resultsUISettingsMap.isNull(
              "isShowSuccessSpinnerImmediateRedirect"
            )
          ) {
            idenfyIdentificationResultsUISettingsV2.isShowSuccessSpinnerImmediateRedirect =
              resultsUISettingsMap.getBoolean("isShowSuccessSpinnerImmediateRedirect")
          }

          idenfyUISettingsV2.idenfyIdentificationResultsUISettingsV2 =
            idenfyIdentificationResultsUISettingsV2
        }

        if (uiSettingsMap.hasKey("immediateRedirectEnum") && !uiSettingsMap.isNull("immediateRedirectEnum")) {
          val enum = uiSettingsMap.getString("immediateRedirectEnum")?.camelToSnakeCase() ?: ""
          idenfyUISettingsV2.immediateRedirectEnum = ImmediateRedirectEnum.valueOf(enum)
        }

        if (uiSettingsMap.hasKey("mismatchTagsAlert") && !uiSettingsMap.isNull("mismatchTagsAlert")) {
          idenfyUISettingsV2.mismatchTagsAlert =
            uiSettingsMap.getBoolean("mismatchTagsAlert")
        }

        if (uiSettingsMap.hasKey("withCountryAndDocumentSelectionJoined") && !uiSettingsMap.isNull("withCountryAndDocumentSelectionJoined")) {
          idenfyUISettingsV2.withCountryAndDocumentSelectionJoined =
            uiSettingsMap.getBoolean("withCountryAndDocumentSelectionJoined")
        }

        if (uiSettingsMap.hasKey("useBottomSheetDialogs") && !uiSettingsMap.isNull("useBottomSheetDialogs")) {
          idenfyUISettingsV2.useBottomSheetDialogs =
            uiSettingsMap.getBoolean("useBottomSheetDialogs")
        }

        if (uiSettingsMap.hasKey("documentCameraFrameVisibility") && !uiSettingsMap.isNull("documentCameraFrameVisibility")) {
          val visibilityMap =
            uiSettingsMap.getMap("documentCameraFrameVisibility")!!
          val visibilityValue = visibilityMap.getString("value")

          idenfyUISettingsV2.documentFrameVisibility = when (visibilityValue) {
            "HiddenForAllCountriesAndDocumentTypes" -> DocumentCameraFrameVisibility.HiddenForAllCountriesAndDocumentTypes
            "HiddenForSpecificCountriesAndDocumentTypes" -> {
              val countriesAndDocuments: Map<String, List<String>> = visibilityMap.getMap("countriesAndDocuments")?.toHashMap() as? Map<String, List<String>>
                ?: emptyMap<String, List<String>>()
              val updatedMap: Map<String, List<DocumentTypeEnum>> = countriesAndDocuments.mapValues { entry ->
                entry.value.mapNotNull {
                  try {
                    DocumentTypeEnum.valueOf(it)
                  } catch (e: IllegalArgumentException) {
                    null
                  }
                }
              }
              DocumentCameraFrameVisibility.HiddenForSpecificCountriesAndDocumentTypes(updatedMap)
            }
            else -> null
          }
        }
      }
    }

    // Outside both config branches on purpose. This assignment is what carries the
    // liveness theme into the SDK, and the app sends no config maps at all.
    idenfySettings.idenfyUISettingsV2 = idenfyUISettingsV2
    return idenfySettings
  }

  fun getFaceAuthSettingsFromConfig(config: ReadableMap): IdenfyFaceAuthUISettings {
    val faceAuthUISettings = IdenfyFaceAuthUISettings()
    val map = config.getMap("idenfyFaceAuthUISettings")

    // getBoolean throws NoSuchKeyException on a missing key, so the old
    // `map?.getBoolean(x) != null` guard could not do what it looked like it did:
    // it only survived because the app sends no map at all. Guard on the key.
    if (map != null && map.hasKey("isLanguageSelectionNeeded") && !map.isNull("isLanguageSelectionNeeded")) {
      faceAuthUISettings.isLanguageSelectionNeeded = map.getBoolean("isLanguageSelectionNeeded")
    }
    if (map != null && map.hasKey("skipOnBoardingView") && !map.isNull("skipOnBoardingView")) {
      faceAuthUISettings.skipOnBoardingView = map.getBoolean("skipOnBoardingView")
    }
    return faceAuthUISettings
  }

  fun getImmediateRedirectFromConfig(config: ReadableMap): Boolean {
    return if (config.hasKey("withImmediateRedirect")) {
      config.getBoolean("withImmediateRedirect")
    } else {
      false
    }
  }

  private fun String.camelToSnakeCase(): String {
    return "(?<=[a-zA-Z])[A-Z]".toRegex().replace(this) {
      "_${it.value}"
    }.uppercase()
  }
}