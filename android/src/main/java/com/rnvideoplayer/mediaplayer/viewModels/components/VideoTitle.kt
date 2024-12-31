package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.TextView

class VideoTitle(context: Context) : FrameLayout(context) {
  private var size: Int = 70
  private val title = createTextView(context)

  init {
    val layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, size).apply {
      gravity = Gravity.TOP or Gravity.START
    }
    addView(title, layoutParams)
  }

  fun setTitle(text: String) {
    title.text = text
  }

  private fun createTextView(context: Context): TextView {
    return TextView(context).apply {
      setTextColor(Color.WHITE)
      textSize = 14f
    }
  }
}
