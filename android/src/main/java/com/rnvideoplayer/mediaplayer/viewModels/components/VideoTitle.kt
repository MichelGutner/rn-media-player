package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.TextView

class VideoTitle(context: Context) : FrameLayout(context) {
  private val title = createTextView(context)

  init {
    val layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
      gravity = Gravity.TOP or Gravity.START
      setMargins(0, 8, 0, 0)
    }
    addView(title, layoutParams)
  }

  fun setTitle(text: String) {
    title.text = text
  }

  private fun createTextView(context: Context): TextView {
    return TextView(context).apply {
      setTextColor(Color.WHITE)
      textSize = 16f
    }
  }
}
