package com.rnvideoplayer.ui.controls

import android.annotation.SuppressLint
import android.content.Context
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import com.rnvideoplayer.R
import com.rnvideoplayer.models.TimesCodes
import com.rnvideoplayer.mediaplayer.viewModels.components.SeekBar
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

  val timeBar = SeekBar(context)

  val timesCodeDuration = TimesCodes(context)
  val timeCodesPosition = TimesCodes(context)
  private val timeCodesView = timesCodesView(context)

  val thumbnails by lazy { Thumbnails(context) }

  val frameLayout = frameLayout(context)

  init {
    fullscreenControlLayout.addView(fullscreenButton)
    buttonsLayout.addView(menuControlLayout)
    buttonsLayout.addView(fullscreenControlLayout)
    frameLayout.addView(buttonsLayout)
    frameLayout.addView(thumbnails)
    mainLayout.addView(frameLayout)
    mainLayout.addView(timeBar)

    mainLayout.addView(timeCodesView)

    addView(mainLayout)
  }

  private fun createButtonsLayout(context: Context): LinearLayout {
    return LinearLayout(context).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.END or Gravity.BOTTOM

      layoutParams = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.MATCH_PARENT
      )
    }
  }

  private fun timesCodesView(context: Context): LinearLayout {
    return LinearLayout(context).apply {
      orientation = LinearLayout.HORIZONTAL
      layoutParams = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.WRAP_CONTENT
      )
      setPadding(dpToPx(8), dpToPx(0), dpToPx(8), dpToPx(0))

      addView(timeCodesPosition.apply {
        layoutParams = LinearLayout.LayoutParams(
          LinearLayout.LayoutParams.WRAP_CONTENT,
          LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
          gravity = Gravity.START
        }
      })

      addView(View(context).apply {
        layoutParams = LinearLayout.LayoutParams(0, 0).apply {
          weight = 1f
        }
      })

      addView(timesCodeDuration.apply {
        layoutParams = LinearLayout.LayoutParams(
          LinearLayout.LayoutParams.WRAP_CONTENT,
          LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
          gravity = Gravity.END
        }
      })
    }
  }

  private fun frameLayout(context: Context): FrameLayout {
    return FrameLayout(context).apply {
      layoutParams = LayoutParams(
        LayoutParams.MATCH_PARENT,
        LayoutParams.WRAP_CONTENT
      ).apply {
        gravity = Gravity.END
      }
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
        setMargins(dpToPx(4),dpToPx(4),dpToPx(4),dpToPx(4))
      }
      setBackgroundResource(R.drawable.rounded_background)
      isClickable = true
      isFocusable = true
      visibility = INVISIBLE
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
      setImageResource(R.drawable.outline_pending_24)
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
        setMargins(dpToPx(4), dpToPx(4), dpToPx(4), dpToPx(4))
      }
      setBackgroundResource(R.drawable.rounded_background)
      visibility = INVISIBLE
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
