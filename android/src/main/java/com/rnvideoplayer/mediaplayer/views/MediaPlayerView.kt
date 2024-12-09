package com.rnvideoplayer.mediaplayer.views

import android.annotation.SuppressLint
import android.view.MotionEvent
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.media3.common.util.UnstableApi
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.mediaplayer.viewModels.MediaPlayerControls
import com.rnvideoplayer.mediaplayer.viewModels.components.AspectRatio
import com.rnvideoplayer.mediaplayer.viewModels.components.FullscreenDialog

@SuppressLint("ViewConstructor")
@UnstableApi
open class MediaPlayerView(private val context: ThemedReactContext) :
  MediaPlayerControls(context) {
  private var fullscreenDialog = FullscreenDialog(context)
  private val aspectRatio = AspectRatio(context)
  private var isPinchGesture: Boolean = false

  init {
    setupLayout()
  }

  private fun setupLayout() {
    aspectRatio.frameLayout.addView(surfaceView)
    addView(aspectRatio.frameLayout)
    addView(overlayView)
  }

  @SuppressLint("ClickableViewAccessibility")
  override fun onTouchEvent(event: MotionEvent): Boolean {
    when (event.actionMasked) {
      MotionEvent.ACTION_DOWN -> {
        // one finger touch start
        if (event.pointerCount == 1) {
          isPinchGesture = false
        }
      }

      MotionEvent.ACTION_POINTER_DOWN -> {
        // gesture with more one finger start
        if (event.pointerCount > 1) {
          isPinchGesture = true
        }
      }

      MotionEvent.ACTION_MOVE -> {
        // check if it's a pinch gesture
        if (event.pointerCount > 1) {
          aspectRatio.pinchGesture.onTouchEvent(event)
        }
      }

      MotionEvent.ACTION_UP -> {
        // finish gesture with one finger
        if (event.pointerCount == 1 && !isPinchGesture) {
          toggleOverlayVisibility()
        }
      }

      MotionEvent.ACTION_POINTER_UP -> {
        // finish gesture with more one finger
        if (event.pointerCount <= 1) {
          isPinchGesture = false
        }
      }
    }
    return true
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    mediaPlayerRelease()
  }

  @SuppressLint("ClickableViewAccessibility")
  override fun onFullscreenMode(isFullscreen: Boolean) {
    val aspectParent = aspectRatio.frameLayout.parent
    val overlayParent = overlayView.parent
    if (aspectParent is ViewGroup) {
      aspectParent.removeView(aspectRatio.frameLayout)
    }
    if (overlayParent is ViewGroup) {
      overlayParent.removeView(overlayView)
    }

    if (isFullscreen) {
      fullscreenDialog = FullscreenDialog(context).apply {
        val container = FrameLayout(context).apply {
          layoutParams = LayoutParams(
            LayoutParams.MATCH_PARENT,
            LayoutParams.MATCH_PARENT
          )
          addView(aspectRatio.frameLayout)
          addView(overlayView)

          setOnTouchListener { _, event ->
            this@MediaPlayerView.onTouchEvent(event)
            true
          }
        }

        setContentView(container)
        show()
      }
    } else {
      fullscreenDialog.dismiss()

      addView(aspectRatio.frameLayout)
      addView(overlayView)
    }
  }
}
