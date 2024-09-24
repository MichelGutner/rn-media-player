package com.rnvideoplayer.ui

import android.annotation.SuppressLint
import android.content.Context
import android.content.res.Configuration
import android.graphics.Point
import android.os.Build
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.core.content.ContextCompat
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.utilities.layoutParamsCenter

@SuppressLint("ViewConstructor")
@UnstableApi
open class VideoPlayerView(private val context: ThemedReactContext) : FrameLayout(context) {
  var player: ExoPlayer? = null
  private val isLandscape =
    context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE

  val viewControls = VideoPlayerControls(context)

  val aspectRatioFrameLayout = AspectRatioFrameLayout(context)
  private val surfaceView: SurfaceView = SurfaceView(context)

  init {
    setupLayout()

    viewControls.setOnClickListener {
      viewControls.toggleOverlay()
    }
  }

  fun setLeftDoubleTapListener(
    onSingleTap: (doubleTapValue: Long) -> Unit,
    onDoubleTap: (doubleTapValue: Long) -> Unit
  ) {
    viewControls.leftDoubleTap.tap(onSingleTap, onDoubleTap)
  }

  fun setRightDoubleTapListener(
    onSingleTap: (doubleTapValue: Long) -> Unit,
    onDoubleTap: (doubleTapValue: Long) -> Unit
  ) {
    viewControls.rightDoubleTap.tap(onSingleTap, onDoubleTap)
  }


  fun setFullscreenOnClickListener(listener: OnClickListener) {
    viewControls.fullscreenButton.setOnClickListener(listener)
  }

  fun setPlayPauseOnClickListener(listener: OnClickListener) {
    viewControls.playPauseButton.setOnClickListener(listener)
  }

  fun setMenuOnClickListener(listener: OnClickListener) {
    viewControls.menuControlLayout.setOnClickListener(listener)
  }

  private fun setupLayout() {
    viewControls.updatePlayPauseIcon(player?.isPlaying ?: true)
    setAspectRatio(calculateModeFitAspectRatio(context))
    setBackgroundColor(ContextCompat.getColor(context, android.R.color.holo_green_dark))

    aspectRatioFrameLayout.addView(surfaceView, 0)
    addView(aspectRatioFrameLayout, -1)
    addView(viewControls, 1)

    surfaceView.holder.addCallback(object : SurfaceHolder.Callback {
      override fun surfaceCreated(holder: SurfaceHolder) {
        player?.setVideoSurfaceHolder(holder)
      }

      override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {}

      override fun surfaceDestroyed(holder: SurfaceHolder) {
        player?.setVideoSurfaceHolder(null)
      }
    })
    aspectRatioFrameLayout.requestLayout()
  }


  fun setAspectRatio(aspectRatio: Float) {
    aspectRatioFrameLayout.setAspectRatio(0f)
    aspectRatioFrameLayout.layoutParams =
      layoutParamsCenter(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
    requestLayout()
  }

//  fun setResizeMode(mode: Int) {
//    aspectRatioFrameLayout.resizeMode = mode
//    requestLayout()
//  }

  private fun calculateModeFitAspectRatio(context: ThemedReactContext): Float {
    val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    val screenSize = Point()

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      val metrics = context.resources.displayMetrics
      screenSize.x = metrics.widthPixels
      screenSize.y = metrics.heightPixels
    } else {
      windowManager.defaultDisplay.getSize(screenSize)
    }

    val width = screenSize.x
    val height = screenSize.y
    if (isLandscape) {
      return width.toFloat() / height.toFloat()
    }
    return height.toFloat() / width.toFloat()
  }
}
