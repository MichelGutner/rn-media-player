package com.rnvideoplayer

import android.annotation.SuppressLint
import android.content.pm.ActivityInfo
import android.net.Uri
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.ui.VideoPlayerView
import com.rnvideoplayer.utilities.layoutParamsCenter

@OptIn(UnstableApi::class)
@SuppressLint("viewConstructor")
class RNVideoPlayerViewX(val context: ThemedReactContext) : VideoPlayerView(context) {
  private val exoPlayer = ExoPlayer.Builder(context).build()
  private var isFullscreen = false

  init {
    this.player = exoPlayer
    aspectRatioFrameLayout.setAspectRatio(2f)
    val mediaItem =
      MediaItem.fromUri(Uri.parse("https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"))
    player?.setMediaItem(mediaItem)
    player?.prepare()
    player?.playWhenReady = true

    setFullscreenOnClickListener {
      println("TESTIGN")
      toggleFullScreen()
    }
  }

  private var currentParent: ViewGroup? = null
  private var currentIndexInParent: Int = -1

  private fun toggleFullScreen() {
    val activity = context.currentActivity ?: return

    if (isFullscreen) {
      (aspectRatioFrameLayout.parent as? ViewGroup)?.removeView(aspectRatioFrameLayout)
      (viewControls.parent as? ViewGroup)?.removeView(viewControls)

      currentParent?.addView(aspectRatioFrameLayout, currentIndexInParent)
      currentParent?.addView(viewControls, 1)

      val layoutParams = layoutParamsCenter(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
      aspectRatioFrameLayout.layoutParams = layoutParams
      aspectRatioFrameLayout.setAspectRatio(2f)

      activity.window.apply {
        decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
        clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
      }
      activity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
    } else {
      currentParent = aspectRatioFrameLayout.parent as? ViewGroup
      currentIndexInParent = currentParent?.indexOfChild(aspectRatioFrameLayout) ?: -1
      currentParent?.removeView(aspectRatioFrameLayout)
      currentParent?.removeView(viewControls)

      (activity.window.decorView as? ViewGroup)?.addView(aspectRatioFrameLayout)
      (activity.window.decorView as? ViewGroup)?.addView(viewControls)
      viewControls.bringToFront()

      aspectRatioFrameLayout.layoutParams = layoutParamsCenter(
        LayoutParams.MATCH_PARENT,
        LayoutParams.MATCH_PARENT
      )

      aspectRatioFrameLayout.setAspectRatio(0f)
      activity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_USER_LANDSCAPE

      activity.window.decorView.systemUiVisibility = (
        View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
          View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
          View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
          View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        )

      activity.window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
    }

    aspectRatioFrameLayout.requestLayout()
    aspectRatioFrameLayout.postInvalidate()

    isFullscreen = !isFullscreen
  }
}
