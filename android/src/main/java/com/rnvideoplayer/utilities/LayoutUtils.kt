package com.rnvideoplayer.utilities

import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout.LayoutParams

fun layoutParamsCenter(width: Int, height: Int): ViewGroup.LayoutParams {
  return LayoutParams(width, height).apply {
    gravity = Gravity.CENTER
  }
}
