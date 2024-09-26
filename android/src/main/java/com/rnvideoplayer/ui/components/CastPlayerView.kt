package com.rnvideoplayer.ui.components

import android.annotation.SuppressLint
import android.content.Context
import android.widget.FrameLayout
import androidx.media3.cast.CastPlayer
import androidx.media3.cast.SessionAvailabilityListener
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.mediarouter.app.MediaRouteButton
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.framework.CastContext

@SuppressLint("ViewConstructor")
@UnstableApi
class CastPlayerView(context: Context, private val exoPlayer: ExoPlayer): FrameLayout(context) {
  private val castContext = CastContext.getSharedInstance(context)
  private val mediaRouteButton = MediaRouteButton(context)
  private val castPlayer = CastPlayer(castContext)

  init {
    // Set up Cast Button
    CastButtonFactory.setUpMediaRouteButton(context, mediaRouteButton)

    // Set up session availability listener to handle casting
    castPlayer.setSessionAvailabilityListener(object : SessionAvailabilityListener {
      override fun onCastSessionAvailable() {
        // Transfer media from ExoPlayer to CastPlayer
        exoPlayer.currentMediaItem?.let { mediaItem ->
          castPlayer.setMediaItem(mediaItem)
          castPlayer.seekTo(exoPlayer.currentPosition)
          castPlayer.play()
          exoPlayer.pause() // Pause local playback
        }
      }

      override fun onCastSessionUnavailable() {
        // Resume local playback when casting session is disconnected
        castPlayer.pause()
        exoPlayer.seekTo(castPlayer.currentPosition)
        exoPlayer.play()
      }
    })

    // Add the cast button to the view
    addView(mediaRouteButton)
  }

  // Optional: Clean up when this view is destroyed
  fun onDestroy() {
    // Release CastPlayer and other resources if needed
    castPlayer.release()
  }
}
