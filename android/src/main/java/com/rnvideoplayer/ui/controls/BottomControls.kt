package com.rnvideoplayer.ui.controls

import android.annotation.SuppressLint
import android.content.Context
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import androidx.annotation.OptIn
import androidx.core.view.marginBottom
import androidx.core.view.setMargins
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.DefaultTimeBar
import com.rnvideoplayer.R
import com.rnvideoplayer.utilities.ColorUtils
import com.rnvideoplayer.utilities.layoutParamsCenter

@OptIn(UnstableApi::class)
class BottomControls(context: Context) : FrameLayout(context) {
  private val mainLayout = createMainLayout(context).apply {
    layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
      gravity = Gravity.BOTTOM
    }
  }
  private val buttonsLayout = createButtonsLayout(context)

  private val barWithTimeCodesDuration = LinearLayout(context).apply {
    orientation = LinearLayout.HORIZONTAL
  }

  val menuControlLayout = createMenuControlLayout(context)
  val fullscreenControlLayout = fullscreenControlLayout(context)

  val timeBar = createTimeBar(context)
  val timeCodesDurationView = createTimeCodesDuration(context)

  init {
    barWithTimeCodesDuration.addView(timeBar)
    barWithTimeCodesDuration.addView(timeCodesDurationView)

    buttonsLayout.addView(menuControlLayout)
    buttonsLayout.addView(fullscreenControlLayout)

    mainLayout.addView(barWithTimeCodesDuration)
    mainLayout.addView(buttonsLayout)

    addView(mainLayout)
  }


  private fun createTimeBar(context: Context): DefaultTimeBar {
    return DefaultTimeBar(context).apply {
      layoutParams = LinearLayout.LayoutParams(
        0,
        ViewGroup.LayoutParams.WRAP_CONTENT
      ).apply {
        weight = 1f
        gravity = Gravity.CENTER
      }
    }
  }

  private fun createTimeCodesDuration(context: Context): FrameLayout {
    val timeCodesDurationView = FrameLayout(context).apply {
      layoutParams = LayoutParams(
        LayoutParams.WRAP_CONTENT,
        LayoutParams.WRAP_CONTENT
      ).apply {
        gravity = Gravity.CENTER
        setPadding(16, 16, 16, 16)
      }
    }
    val timeCodesDuration = TextView(context).apply {
      setTextColor(ColorUtils.white)
      layoutParams = layoutParamsCenter(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
      text = context.getString(R.string.time_codes_start_value)
    }
    timeCodesDurationView.addView(timeCodesDuration)

    return timeCodesDurationView
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
    val fullscreenControlLayout = LinearLayout(context).apply {
      layoutParams = LinearLayout.LayoutParams(dpToPx(40), dpToPx(40)).apply {
        setMargins(dpToPx(4),dpToPx(4),dpToPx(4),dpToPx(8))
      }
      setBackgroundResource(R.drawable.rounded_background)
      isClickable = true
      isFocusable = true
    }
    val fullscreenIcon = ImageButton(context).apply {
      layoutParams = LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
      val typedValue = TypedValue()
      context.theme.resolveAttribute(
        android.R.attr.selectableItemBackgroundBorderless,
        typedValue,
        true
      )
      setBackgroundResource(typedValue.resourceId)
      setImageResource(R.drawable.animated_full_to_exit)
      isClickable = false
      isFocusable = false
    }
    fullscreenControlLayout.addView(fullscreenIcon)
    return fullscreenControlLayout
  }


  private fun dpToPx(dp: Int): Int {
    return (dp * context.resources.displayMetrics.density).toInt()
  }
}
