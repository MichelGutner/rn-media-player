package com.rnvideoplayer.mediaplayer.utils
import android.graphics.Color

class Utils {
  companion object {
    const val DEFAULT_ASPECT_RATIO = 2f
    private const val ALPHA = 255 * 0.3

    val COLOR_BLACK_ALPHA_03 = Color.argb(ALPHA.toInt(), 0, 0, 0)
    val WHITE = Color.argb(255, 255, 255, 255)
  }
}
