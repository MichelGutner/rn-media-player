package com.rnvideoplayer.cast

import android.content.Context
import android.text.format.DateUtils
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.framework.media.CastMediaOptions
import com.google.android.gms.cast.framework.media.MediaIntentReceiver
import com.google.android.gms.cast.framework.media.NotificationOptions

@Suppress("UNUSED")
class CastOptionsProvider : OptionsProvider {
  override fun getCastOptions(context: Context): CastOptions {
    val buttonActions: MutableList<String> = ArrayList()
    buttonActions.add(MediaIntentReceiver.ACTION_REWIND)
    buttonActions.add(MediaIntentReceiver.ACTION_TOGGLE_PLAYBACK)
    buttonActions.add(MediaIntentReceiver.ACTION_FORWARD)
    buttonActions.add(MediaIntentReceiver.ACTION_STOP_CASTING)

    val compatButtonActionsIndices = intArrayOf(1, 3)

    val notificationOptions = NotificationOptions.Builder()
      .setActions(buttonActions, compatButtonActionsIndices)
      .setSkipStepMs(30 * DateUtils.SECOND_IN_MILLIS)
      .build()

    val mediaOptions = CastMediaOptions.Builder()
      .setNotificationOptions(notificationOptions)
      .build()

    return CastOptions.Builder()
      .setReceiverApplicationId(CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID)
      .setCastMediaOptions(mediaOptions)
      .build()
  }

  override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
    return null
  }
}
