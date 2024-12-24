package com.rnvideoplayer.mediaplayer.views

import android.annotation.SuppressLint
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.view.MotionEvent
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.media3.common.util.UnstableApi
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.mediaplayer.models.ReactEventsName
import com.rnvideoplayer.mediaplayer.models.ReactEventsAdapter
import com.rnvideoplayer.mediaplayer.viewModels.MediaPlayerControls
import com.rnvideoplayer.mediaplayer.viewModels.components.AspectRatio
import kotlin.math.roundToInt

@SuppressLint("ViewConstructor")
@UnstableApi
open class MediaPlayerView(private val context: ThemedReactContext) :
  MediaPlayerControls(context) {
  private val reactApplicationEventEmitter = ReactEventsAdapter(context)
  private var fullscreenDialog = FullscreenDialog(context)
  private val aspectRatio = AspectRatio(context)
  private var clickCount = 0
  private var lastClickTime = 0L
  private var isPinchGesture: Boolean = false

  private val container = FrameLayout(context).apply {
    layoutParams = LayoutParams(
      LayoutParams.MATCH_PARENT,
      LayoutParams.MATCH_PARENT
    )
  }

  init {
    setupLayout()
  }

  private fun setupLayout() {
    addEvents(reactApplicationEventEmitter)
    aspectRatio.frameLayout.addView(surfaceView)
    container.addView(aspectRatio.frameLayout)

    container.addView(controlsContainer)
    controlsContainer.bringToFront()
    addView(container)
  }

  @SuppressLint("ClickableViewAccessibility")
  override fun onTouchEvent(event: MotionEvent): Boolean {
    when (event.actionMasked) {
      MotionEvent.ACTION_DOWN -> {
        val currentTime = System.currentTimeMillis()

        if (event.pointerCount == 1) {
          isPinchGesture = false
        }
        if (currentTime - lastClickTime < 300) {
          clickCount++
        } else {
          clickCount = 1
        }
        lastClickTime = currentTime
      }

      MotionEvent.ACTION_POINTER_DOWN -> {
        if (event.pointerCount > 1) {
          isPinchGesture = true
        }
      }

      MotionEvent.ACTION_MOVE -> {
        if (event.pointerCount > 1) {
          aspectRatio.pinchGesture.onTouchEvent(event)
        }
      }

      MotionEvent.ACTION_UP -> {
        if (event.pointerCount == 1 && !isPinchGesture && clickCount < 2) {
          toggleOverlayVisibility()
          performClick()
        } else {
          val roundedScaleX = (aspectRatio.frameLayout.scaleX * 100).roundToInt() / 100f
          val currentZoom = if (roundedScaleX > 1) "resizeAspectFill" else "resizeAspect"
          reactApplicationEventEmitter.send(
            ReactEventsName.MEDIA_PINCH_ZOOM,
            this@MediaPlayerView,
            Arguments.createMap().apply {
              putString("currentZoom", currentZoom)
            }
          )
        }

        if (clickCount >= 2) {
          if (event.x < width / 2) {
            leftSeekGestureView.show()
            leftSeekGestureView.hide()
          } else {
            rightSeekGestureView.show()
            rightSeekGestureView.hide()
          }
        }
      }

      MotionEvent.ACTION_POINTER_UP -> {
        if (event.pointerCount <= 1) {
          isPinchGesture = false
        }
      }
    }
    return true
  }

  override fun performClick(): Boolean {
    return super.performClick()
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    mediaPlayerRelease()
    context.currentActivity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
  }

  override fun onConfigurationChanged(newConfig: Configuration?) {
    super.onConfigurationChanged(newConfig)
    if (newConfig?.orientation == Configuration.ORIENTATION_PORTRAIT && fullscreenDialog.isShowing) {
      context.currentActivity?.requestedOrientation =
        ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
    }
  }

  @SuppressLint("ClickableViewAccessibility", "SourceLockedOrientationActivity")
  override fun onFullscreenMode(isFullscreen: Boolean) {
    val parent = container.parent
    if (parent is ViewGroup) {
      parent.removeView(container)
    }

    if (isFullscreen) {
      fullscreenDialog = FullscreenDialog(context).apply {
        setOnDismissListener {
          onFullscreenMode(false)
        }
        container.setOnTouchListener { _, event ->
          this@MediaPlayerView.onTouchEvent(event)
          true
        }
        setContentView(container)
        show()
      }

      context.currentActivity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE

    } else {
      context.currentActivity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT

      context.currentActivity?.window?.decorView?.postDelayed({
        context.currentActivity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
      }, 2500)
      fullscreenDialog.dismiss()
      addView(container)
    }
  }
}
