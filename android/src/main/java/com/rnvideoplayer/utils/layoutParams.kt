package com.rnvideoplayer.utils

import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout.LayoutParams

fun layoutParamsWithGravityCenter(width: Int, height: Int): ViewGroup.LayoutParams {
  return LayoutParams(width, height).apply {
    gravity = Gravity.CENTER
  }
}
