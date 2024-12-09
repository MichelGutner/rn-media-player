package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.view.Gravity
import android.view.ScaleGestureDetector
import android.widget.FrameLayout
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import com.rnvideoplayer.mediaplayer.utils.Utils

@UnstableApi
class AspectRatio(context: Context) : FrameLayout(context) {
  lateinit var pinchGesture: ScaleGestureDetector
  val frameLayout: AspectRatioFrameLayout = AspectRatioFrameLayout(context)

  init {
      createAspectRatio()
  }

  private fun createAspectRatio() {
    val layoutParams = LayoutParams(
      LayoutParams.MATCH_PARENT,
      LayoutParams.MATCH_PARENT
    ).apply {
      gravity = Gravity.CENTER
    }
    frameLayout.layoutParams = layoutParams
    frameLayout.setAspectRatio(Utils.DEFAULT_ASPECT_RATIO)
    addPinchGesture()
  }

  private fun addPinchGesture() {
    pinchGesture =
      ScaleGestureDetector(context, object : ScaleGestureDetector.OnScaleGestureListener {
        override fun onScale(detector: ScaleGestureDetector): Boolean {
          val currentScale = detector.scaleFactor

          val newScaleX = frameLayout.scaleX * currentScale
          val newScaleY = frameLayout.scaleY * currentScale

          if (newScaleX in 1.0..1.2 && newScaleY in 1.0..1.2) {
            frameLayout.scaleX = newScaleX
            frameLayout.scaleY = newScaleY
          }

          return true
        }

        override fun onScaleBegin(detector: ScaleGestureDetector): Boolean {
          return true
        }
        override fun onScaleEnd(detector: ScaleGestureDetector) {}
      })
  }
}
