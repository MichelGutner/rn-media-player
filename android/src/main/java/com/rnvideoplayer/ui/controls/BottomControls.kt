package com.rnvideoplayer.ui.controls

import android.annotation.SuppressLint
import android.content.Context
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import com.rnvideoplayer.R
import com.rnvideoplayer.components.CustomTimeBar
import com.rnvideoplayer.ui.components.Thumbnails
import com.rnvideoplayer.utilities.layoutParamsCenter

@OptIn(UnstableApi::class)
class BottomControls(context: Context) : FrameLayout(context) {
  private val mainLayout = createMainLayout(context).apply {
    layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
      gravity = Gravity.BOTTOM
    }
  }
  private val buttonsLayout = createButtonsLayout(context)



  val menuControlLayout = createMenuControlLayout(context)
  val fullscreenControlLayout = fullscreenControlLayout(context)
  val fullscreenButton = createFullscreenButtonAnimated(context)

  val timeBar = CustomTimeBar(context)
  val thumbnails by lazy { Thumbnails(context) }


  init {
    fullscreenControlLayout.addView(fullscreenButton)

    buttonsLayout.addView(menuControlLayout)
    buttonsLayout.addView(fullscreenControlLayout)
    mainLayout.addView(thumbnails)
    mainLayout.addView(timeBar)
    mainLayout.addView(buttonsLayout)

    addView(mainLayout)
  }

  private fun createButtonsLayout(context: Context): LinearLayout {
    return LinearLayout(context).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.END
    }
  }

  private fun createMainLayout(context: Context): LinearLayout {
    return LinearLayout(context).apply {
      orientation = LinearLayout.VERTICAL
      gravity = Gravity.BOTTOM
    }
  }

  @SuppressLint("ResourceType")
  private fun createMenuControlLayout(context: Context): LinearLayout {
    val menuControlLayout = LinearLayout(context).apply {
      layoutParams = LinearLayout.LayoutParams(dpToPx(40), dpToPx(40)).apply {
        setMargins(dpToPx(4),dpToPx(4),dpToPx(4),dpToPx(8))
      }
      setBackgroundResource(R.drawable.rounded_background)
      isClickable = true
      isFocusable = true
    }

    val menuIcon = ImageButton(context).apply {
      layoutParams = LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
      val typedValue = TypedValue()
      context.theme.resolveAttribute(
        android.R.attr.selectableItemBackgroundBorderless,
        typedValue,
        true
      )
      setBackgroundResource(typedValue.resourceId)
      setImageResource(R.drawable.baseline_more_horiz_24)
      isClickable = false
      isFocusable = false
    }
    menuControlLayout.addView(menuIcon)

    return menuControlLayout
  }

  @SuppressLint("ResourceType")
  private fun fullscreenControlLayout(context: Context): LinearLayout {
    return LinearLayout(context).apply {
      layoutParams = LinearLayout.LayoutParams(dpToPx(40), dpToPx(40)).apply {
        setMargins(dpToPx(4), dpToPx(4), dpToPx(4), dpToPx(8))
      }
      setBackgroundResource(R.drawable.rounded_background)
    }
  }

  @SuppressLint("ResourceType")
  fun createFullscreenButtonAnimated(context: Context): ImageButton {
    return ImageButton(context).apply {
      layoutParams =
        layoutParamsCenter(LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
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


  private fun dpToPx(dp: Int): Int {
    return (dp * context.resources.displayMetrics.density).toInt()
  }
}
