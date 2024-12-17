package com.rnvideoplayer.ui

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.graphics.Point
import android.os.Build
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver.OnGlobalLayoutListener
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.core.content.ContextCompat
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.helpers.SharedStore
import com.rnvideoplayer.utilities.layoutParamsCenter
import java.lang.ref.WeakReference

@SuppressLint("ViewConstructor")
@UnstableApi
open class VideoPlayerView(private val context: ThemedReactContext) : FrameLayout(context) {
  var player: ExoPlayer? = null
  private val isLandscape =
    context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
  private val activity = context.currentActivity
  var isFullscreen = false
  private var currentIndexInParent: Int = -1

  private var aspectRatio: Float = 2f

  private var autoEnterFullscreenOnLandscape = false

  val viewControls = VideoPlayerControls(context)

  val aspectRatioFrameLayout = AspectRatioFrameLayout(context)
  private val surfaceView: SurfaceView = SurfaceView(context)

  val weakActivity = WeakReference(activity)

  init {
    viewTreeObserver.addOnGlobalLayoutListener(object : OnGlobalLayoutListener {
      override fun onGlobalLayout() {
        weakActivity.get() ?: return
        autoEnterFullscreenOnLandscape =
          SharedStore.getInstance().getBoolean("autoEnterFullscreenOnLandscape") ?: false
        viewTreeObserver.removeOnGlobalLayoutListener(this)
      }
    })

    setupLayout()
  }

  override fun onConfigurationChanged(newConfig: Configuration?) {
    super.onConfigurationChanged(newConfig)
    val landscapeOrientation = newConfig?.orientation == Configuration.ORIENTATION_LANDSCAPE
    if (autoEnterFullscreenOnLandscape && !isFullscreen && landscapeOrientation) {
      enterInFullScreen()
    }
  }

  fun playbackViewClickListener(listener: OnClickListener) {
    viewControls.setOnClickListener(listener)
  }

  fun isReadyToDisplayControls() {
    viewControls.loading.hide()
    viewControls.playPauseButton.visibility = VISIBLE
    viewControls.fullscreenLayout.visibility = VISIBLE
    viewControls.menuControlLayout.visibility = VISIBLE
    viewControls.timeBar.visibility = VISIBLE
    viewControls.timeCodesPosition.visibility = VISIBLE
    viewControls.timeCodesDuration.visibility = VISIBLE
    viewControls.title.visibility = VISIBLE
  }

  fun unReadyToDisplayControls() {
    viewControls.playPauseButton.visibility = INVISIBLE
    viewControls.fullscreenLayout.visibility = INVISIBLE
    viewControls.menuControlLayout.visibility = INVISIBLE
  }

  fun hideControlsWithoutTimebar() {
    viewControls.playPauseRoundedBackground.visibility = INVISIBLE
    viewControls.fullscreenLayout.visibility = INVISIBLE
    viewControls.menuControlLayout.visibility = INVISIBLE
  }

  fun showButtons() {
    viewControls.playPauseRoundedBackground.visibility = VISIBLE
    viewControls.fullscreenLayout.visibility = VISIBLE
    viewControls.menuControlLayout.visibility = VISIBLE
  }

  fun setLeftDoubleTapListener(
    onSingleTap: (doubleTapValue: Long) -> Unit,
    onDoubleTap: (doubleTapValue: Long) -> Unit
  ) {
//    viewControls.leftDoubleTap.tap(onSingleTap, onDoubleTap)
  }

  fun setRightDoubleTapListener(
    onSingleTap: (doubleTapValue: Long) -> Unit,
    onDoubleTap: (doubleTapValue: Long) -> Unit
  ) {
//    viewControls.rightDoubleTap.tap(onSingleTap, onDoubleTap)
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
    setAspectRatio(calculateModeFitAspectRatio(context))
    setBackgroundColor(ContextCompat.getColor(context, android.R.color.black))
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
    aspectRatioFrameLayout.setAspectRatio(aspectRatio)
    aspectRatioFrameLayout.layoutParams =
      layoutParamsCenter(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
    requestLayout()
  }

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

  fun enterInFullScreen() {
    activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
    currentIndexInParent = indexOfChild(aspectRatioFrameLayout)
    removeView(aspectRatioFrameLayout)
    removeView(viewControls)

    (activity?.window?.decorView as? ViewGroup)?.addView(aspectRatioFrameLayout)
    (activity?.window?.decorView as? ViewGroup)?.addView(viewControls)
    viewControls.bringToFront()

    aspectRatioFrameLayout.layoutParams = layoutParamsCenter(
      LayoutParams.MATCH_PARENT,
      LayoutParams.MATCH_PARENT
    )

    aspectRatioFrameLayout.setAspectRatio(0f)

    activity?.window?.decorView?.systemUiVisibility = (
      View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
        View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
        View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
        View.SYSTEM_UI_FLAG_LAYOUT_STABLE
      )

    activity?.window?.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
    isFullscreen = true
    viewControls.updateFullscreenIcon(true)
    aspectRatioFrameLayout.requestLayout()
    aspectRatioFrameLayout.postInvalidate()
  }

  fun exitFromFullScreen() {
    activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED

    val parentAspect = aspectRatioFrameLayout.parent as? ViewGroup
    val parentControls = viewControls.parent as? ViewGroup
   parentAspect?.removeView(aspectRatioFrameLayout)
    parentControls?.removeView(viewControls)

    addView(aspectRatioFrameLayout, 0)
    addView(viewControls, 1)

    aspectRatioFrameLayout.layoutParams =
      layoutParamsCenter(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
    aspectRatioFrameLayout.setAspectRatio(aspectRatio)

    activity?.window?.apply {
      decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
      clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
    }

    isFullscreen = false
    viewControls.updateFullscreenIcon(false)
    aspectRatioFrameLayout.requestLayout()
    aspectRatioFrameLayout.postInvalidate()
  }
}
