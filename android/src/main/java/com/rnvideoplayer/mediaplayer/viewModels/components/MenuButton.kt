package com.rnvideoplayer.mediaplayer.viewModels.components

import android.annotation.SuppressLint
import android.content.Context
import android.util.TypedValue
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import com.rnvideoplayer.R


class MenuButton(context: Context) : LinearLayout(context) {
  private var size: Int = 60
  private val button = setupButton(context)

  init {
    addView(button)
    setPadding(0,0,16,0)
    requestLayout()
  }

  override fun setOnClickListener(l: OnClickListener?) {
    button.setOnClickListener(l)
  }

  @SuppressLint("ResourceType")
  private fun setupButton(context: Context): ImageButton {
    return ImageButton(context).apply {
      layoutParams = LayoutParams(size, size).apply {
        gravity = Gravity.CENTER
      }
      val typedValue = TypedValue()
      context.theme.resolveAttribute(
        android.R.attr.selectableItemBackgroundBorderless,
        typedValue,
        true
      )
      setBackgroundResource(typedValue.resourceId)
      setImageResource(R.drawable.outline_pending_24)
    }
  }
}
