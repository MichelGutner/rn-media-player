package com.rnvideoplayer.utilities

import android.graphics.Color

class ColorUtils {
  companion object {
    private val alphaCalculated = 255 * 0.5

    val blackOpacity50 = Color.argb(alphaCalculated.toInt(), 0, 0, 0)
    val white = Color.argb(255, 255, 255, 255)
  }
}
