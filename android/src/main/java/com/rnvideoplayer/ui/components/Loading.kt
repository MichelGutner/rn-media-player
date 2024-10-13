package com.rnvideoplayer.ui.components

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.util.TypedValue
import android.view.View
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ProgressBar
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.utilities.layoutParamsCenter

@SuppressLint("ViewConstructor")
class Loading(context: ThemedReactContext): FrameLayout(context) {
  private val loading = createLoading(context)

  fun show() {
    visibility = View.VISIBLE
  }

  fun hide() {
    visibility = View.INVISIBLE
  }

  init {
    addView(loading)
  }

  private fun createLoading(context: Context): ProgressBar {
    val sizeInPx = TypedValue.applyDimension(
      TypedValue.COMPLEX_UNIT_DIP,
      50f,
      context.resources.displayMetrics
    ).toInt()
    return ProgressBar(context).apply {
      layoutParams = layoutParamsCenter(sizeInPx, sizeInPx)
      isIndeterminate = true
      interpolator = AccelerateDecelerateInterpolator()
      indeterminateDrawable.setColorFilter(Color.BLUE, android.graphics.PorterDuff.Mode.SRC_IN)
    }
  }
}
