package com.rnvideoplayer.mediaplayer.viewModels.components

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import androidx.core.view.setPadding
import com.rnvideoplayer.R

class FullscreenButton(context: Context) : FrameLayout(context) {
  private var size: Int = 80
  private val button = setupButton(context)

  init {
    setupLayout()
    addView(button)
  }

  override fun setOnClickListener(l: OnClickListener?) {
    button.setOnClickListener(l)
  }

  private fun setupLayout() {
    layoutParams = LayoutParams(
      ViewGroup.LayoutParams.WRAP_CONTENT,
      ViewGroup.LayoutParams.WRAP_CONTENT
    ).apply {
      gravity = Gravity.CENTER
    }
    setPadding(8)
  }

  @SuppressLint("ResourceType")
  private fun setupButton(context: Context): ImageButton {
    return ImageButton(context).apply {
      val typedValue = TypedValue()
      context.theme.resolveAttribute(
        android.R.attr.selectableItemBackgroundBorderless,
        typedValue,
        true
      )
      setBackgroundResource(typedValue.resourceId)
      setImageResource(R.drawable.animated_full_to_exit)
    }
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
