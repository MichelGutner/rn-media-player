package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.view.Gravity
import android.widget.RelativeLayout
import android.widget.TextView
import com.rnvideoplayer.utilities.ColorUtils
import com.rnvideoplayer.utilities.layoutParamsCenter

class Title(context: Context) : RelativeLayout(context) {
  private val title = createTextView(context)

  init {
    addView(title)
  }

  fun setTitle(text: String) {
    title.text = text
  }

  private fun createTextView(context: Context): TextView {
    return TextView(context).apply {
      setTextColor(ColorUtils.white)
      textSize = 16f
      gravity = Gravity.START
      layoutParams = layoutParamsCenter(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
    }
  }
}
