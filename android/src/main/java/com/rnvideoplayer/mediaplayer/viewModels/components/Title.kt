package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.widget.RelativeLayout
import android.widget.TextView
import com.rnvideoplayer.utils.layoutParamsWithGravityCenter

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
      setTextColor(Color.WHITE)
      textSize = 16f
      gravity = Gravity.START
      layoutParams = layoutParamsWithGravityCenter(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
    }
  }
}
