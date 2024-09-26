package com.rnvideoplayer.providers

import android.content.Context
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider

class MyCastOptionsProvider : OptionsProvider {

  companion object {
    // Default Google Cast receiver app ID
    const val DEFAULT_APP_ID = "CC1AD845"
    const val CUSTOM_NAMESPACE = "urn:x-cast:custom_namespace"
  }

  override fun getCastOptions(context: Context): CastOptions {
    // Add custom namespaces if needed
    val supportedNamespaces = mutableListOf<String>()
    supportedNamespaces.add(CUSTOM_NAMESPACE)

    return CastOptions.Builder()
      .setReceiverApplicationId(DEFAULT_APP_ID)
      .setSupportedNamespaces(supportedNamespaces)
      .build()
  }

  override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
    return null
  }
}
