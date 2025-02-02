package com.rnvideoplayer.cast

import com.google.android.gms.cast.framework.OptionsProvider
import android.content.Context
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.LaunchOptions
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.media.NotificationOptions
import com.google.android.gms.cast.framework.media.MediaIntentReceiver
import com.google.android.gms.cast.framework.media.CastMediaOptions
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.framework.media.ImagePicker
import com.google.android.gms.cast.framework.media.ImageHints
import com.google.android.gms.common.images.WebImage
import com.rnvideoplayer.expandedcontrols.ExpandedControlsActivity

/**
 * Implements [OptionsProvider] to provide [CastOptions].
 */
@Suppress("UNUSED")
class CastOptionsProvider : OptionsProvider {

  override fun getCastOptions(appContext: Context): CastOptions {
    return CastOptions.Builder()
      .setReceiverApplicationId(CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID)
      .build()
  }

  override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
    return null
  }
}

//class CastOptionsProvider : OptionsProvider {
//  override fun getCastOptions(context: Context): CastOptions {
//    val notificationOptions = NotificationOptions.Builder()
//      .setActions(
//        listOf(
//          MediaIntentReceiver.ACTION_SKIP_NEXT,
//          MediaIntentReceiver.ACTION_TOGGLE_PLAYBACK,
//          MediaIntentReceiver.ACTION_STOP_CASTING
//        ), intArrayOf(1, 2)
//      )
//      .setTargetActivityClassName(ExpandedControlsActivity::class.java.name)
//      .build()
//    val mediaOptions = CastMediaOptions.Builder()
//      .setImagePicker(ImagePickerImpl())
//      .setNotificationOptions(notificationOptions)
//      .setExpandedControllerActivityClassName(ExpandedControlsActivity::class.java.name)
//      .build()
//    /** Following lines enable Cast Connect  */
//    val launchOptions = LaunchOptions.Builder()
//      .setAndroidReceiverCompatible(true)
//      .build()
//    return CastOptions.Builder()
//      .setLaunchOptions(launchOptions)
//      .setReceiverApplicationId(CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID)
//      .setRemoteToLocalEnabled(true)
//      .setCastMediaOptions(mediaOptions)
//      .build()
//  }
//
//  override fun getAdditionalSessionProviders(appContext: Context): List<SessionProvider>? {
//    return null
//  }
//
//  private class ImagePickerImpl : ImagePicker() {
//    override fun onPickImage(mediaMetadata: MediaMetadata?, hints: ImageHints): WebImage? {
//      val type = hints.type
//      if (!mediaMetadata!!.hasImages()) {
//        return null
//      }
//      val images = mediaMetadata.images
//      return if (images.size == 1) {
//        images[0]
//      } else {
//        if (type == IMAGE_TYPE_MEDIA_ROUTE_CONTROLLER_DIALOG_BACKGROUND) {
//          images[0]
//        } else {
//          images[1]
//        }
//      }
//    }
//  }
//}
