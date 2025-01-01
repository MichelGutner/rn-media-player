package com.rnvideoplayer.utils
import android.graphics.Color
import android.view.View
import android.view.animation.AccelerateDecelerateInterpolator

class Utils {
  companion object {
    const val DEFAULT_ASPECT_RATIO = 2f
    private const val ALPHA = 255 * 0.3
    private const val ALPHA_02 = 255 * 0.2
    private const val ALPHA_05 = 255 * 0.5

    val COLOR_BLACK_ALPHA_03 = Color.argb(ALPHA.toInt(), 0, 0, 0)
    val COLOR_BLACK_ALPHA_02 = Color.argb(ALPHA_02.toInt(), 0, 0, 0)
    val COLOR_BLACK_ALPHA_05 = Color.argb(ALPHA_05.toInt(), 0, 0, 0)
    val WHITE = Color.argb(255, 255, 255, 255)
  }
}
