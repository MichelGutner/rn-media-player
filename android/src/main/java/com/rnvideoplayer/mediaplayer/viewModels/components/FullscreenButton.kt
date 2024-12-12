package com.rnvideoplayer.mediaplayer.viewModels.components

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.util.TypedValue
import android.view.Gravity
import android.widget.ImageButton
import android.widget.LinearLayout
import com.rnvideoplayer.R

class FullscreenButton(context: Context) : LinearLayout(context) {
  private var size: Int = 100
  private val button = setupButton(context)

  init {
    setupLayout()
      setPadding(16,16,16,16)
      setBackgroundColor(Color.YELLOW)
    addView(button)
  }

  override fun setOnClickListener(l: OnClickListener?) {
    button.setOnClickListener(l)
  }

  private fun setupLayout() {
    layoutParams = LayoutParams(size, size).apply {
      gravity = Gravity.END or Gravity.BOTTOM
    }
    setBackgroundResource(R.drawable.rounded_background)
  }

  @SuppressLint("ResourceType")
  private fun setupButton(context: Context): ImageButton {
    return ImageButton(context).apply {
      layoutParams = LayoutParams(size, size)
      val typedValue = TypedValue()
      context.theme.resolveAttribute(
        android.R.attr.selectableItemBackgroundBorderless,
        typedValue,
        true
      )
      setBackgroundResource(typedValue.resourceId)
      setImageResource(R.drawable.animated_full_to_exit)
      gravity = Gravity.CENTER
    }
  }

  fun setSize(value: Int) {
    size = value
    setupLayout()
    requestLayout()
  }

  fun updateFullscreenIcon(isFullscreen: Boolean) {
    if (isFullscreen) {
      button.setImageResource(R.drawable.animated_exit_to_full)
    } else {
      button.setImageResource(R.drawable.animated_full_to_exit)
    }
    button.postInvalidate()
    button.requestLayout()
  }
}
