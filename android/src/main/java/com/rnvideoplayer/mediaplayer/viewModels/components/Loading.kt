package com.rnvideoplayer.mediaplayer.viewModels.components

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.util.TypedValue
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ProgressBar
import com.rnvideoplayer.utils.layoutParamsWithGravityCenter

@SuppressLint("ViewConstructor")
class Loading(context: Context): FrameLayout(context) {
  private val loading = progressBar(context)

  init {
    setBackgroundColor(Color.BLACK)
    addView(loading)
  }

  private fun progressBar(context: Context): ProgressBar {
    val sizeInPx = TypedValue.applyDimension(
      TypedValue.COMPLEX_UNIT_DIP,
      60f,
      context.resources.displayMetrics
    ).toInt()
    return ProgressBar(context).apply {
      layoutParams = layoutParamsWithGravityCenter(sizeInPx, sizeInPx)
      isIndeterminate = true
      interpolator = AccelerateDecelerateInterpolator()
      indeterminateDrawable.setColorFilter(Color.WHITE, android.graphics.PorterDuff.Mode.SRC_IN)
    }
  }
}
