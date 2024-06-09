package com.rnvideoplayer.providers

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.cast.DefaultCastOptionsProvider.APP_ID_DEFAULT_RECEIVER_WITH_DRM
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider
import androidx.media3.common.util.UnstableApi

class MyCastOptionsProvider : OptionsProvider {
  companion object {
    const val CUSTOM_NAMESPACE = "urn:x-cast:custom_namespace"
  }

  @OptIn(UnstableApi::class)
  override fun getCastOptions(context: Context): CastOptions {
    val supportedNamespaces: MutableList<String> = ArrayList()
    supportedNamespaces.add(CUSTOM_NAMESPACE)

    return CastOptions.Builder()
      .setReceiverApplicationId(APP_ID_DEFAULT_RECEIVER_WITH_DRM)
      .setSupportedNamespaces(supportedNamespaces)
      .build()
  }

  override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
    return null
  }
}
