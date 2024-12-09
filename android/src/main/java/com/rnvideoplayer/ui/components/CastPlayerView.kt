package com.rnvideoplayer.ui.components

import android.annotation.SuppressLint
import android.content.Context
import android.view.Gravity
import android.widget.FrameLayout
import androidx.core.content.ContextCompat
import androidx.media3.cast.CastPlayer
import androidx.media3.cast.SessionAvailabilityListener
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.mediarouter.app.MediaRouteButton
import com.google.android.gms.cast.CastStatusCodes
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastState
import com.rnvideoplayer.R

@SuppressLint("ViewConstructor")
@UnstableApi
class CastPlayerView(context: Context, private val exoPlayer: ExoPlayer) : FrameLayout(context) {
  private val mCastContext = CastContext.getSharedInstance(context)
  private val mMediaRouteButton = MediaRouteButton(context)
  private val castPlayer = CastPlayer(mCastContext)

  init {
    if (mCastContext.castState == CastState.CONNECTED) {
      val reasonCode = mCastContext.getCastReasonCodeForCastStatusCode(CastStatusCodes.ERROR_NO_CAST_CONFIGURATION)
      println("TEST cast reason code: $reasonCode")
    } else {
      println("CastContext not initialized yet")
    }

    CastButtonFactory.setUpMediaRouteButton(context, mMediaRouteButton)
    mMediaRouteButton.setRemoteIndicatorDrawable(ContextCompat.getDrawable(context, R.drawable.baseline_cast_24))

    castPlayer.setSessionAvailabilityListener(object : SessionAvailabilityListener {
      override fun onCastSessionAvailable() {
        exoPlayer.currentMediaItem?.let { mediaItem ->
          castPlayer.setMediaItem(mediaItem)
          castPlayer.seekTo(exoPlayer.currentPosition)
          castPlayer.play()
          exoPlayer.pause()
        }
      }

      override fun onCastSessionUnavailable() {
        castPlayer.pause()
        exoPlayer.seekTo(castPlayer.currentPosition)
        exoPlayer.play()
      }
    })

    val layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
      gravity = Gravity.TOP or Gravity.END
    }
    addView(mMediaRouteButton, layoutParams)
  }

  fun onDestroy() {
    castPlayer.release()
  }
}
