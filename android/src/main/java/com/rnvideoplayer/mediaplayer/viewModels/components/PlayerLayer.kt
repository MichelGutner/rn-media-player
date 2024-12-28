package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.view.Gravity
import android.view.ScaleGestureDetector
import android.widget.FrameLayout
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import com.rnvideoplayer.utils.Utils

@UnstableApi
open class PlayerLayer(context: Context) : FrameLayout(context) {
  lateinit var pinchGesture: ScaleGestureDetector
  val frame: AspectRatioFrameLayout = AspectRatioFrameLayout(context)

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
    frame.layoutParams = layoutParams
    frame.setAspectRatio(Utils.DEFAULT_ASPECT_RATIO)
    addPinchGesture()
  }

  private fun addPinchGesture() {
    pinchGesture =
      ScaleGestureDetector(context, object : ScaleGestureDetector.OnScaleGestureListener {
        override fun onScale(detector: ScaleGestureDetector): Boolean {
          val currentScale = detector.scaleFactor

          val newScaleX = frame.scaleX * currentScale
          val newScaleY = frame.scaleY * currentScale

          if (newScaleX in 1.0..1.2 && newScaleY in 1.0..1.2) {
            frame.scaleX = newScaleX
            frame.scaleY = newScaleY
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
