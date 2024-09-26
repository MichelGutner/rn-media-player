package com.rnvideoplayer.ui.components

import android.content.Context
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.DefaultTimeBar
import androidx.media3.ui.TimeBar.OnScrubListener
import com.rnvideoplayer.R
import com.rnvideoplayer.helpers.RNVideoHelpers
import com.rnvideoplayer.interfaces.ICustomSeekBar
import com.rnvideoplayer.utilities.ColorUtils
import com.rnvideoplayer.utilities.layoutParamsCenter

@UnstableApi
class CustomTimeBar(context: Context) : LinearLayout(context), ICustomSeekBar {
  private var helper = RNVideoHelpers()
  var timeBarWidth: Int = 0
    private set

  private val timeCodesDurationView = createTimeCodesDurationView(context)
  private val timeCodesDuration = createTimeCodesDuration(context)

  private val barWithTimeCodesDuration = LinearLayout(context).apply {
    orientation = HORIZONTAL
  }

  private val timeBar = createTimeBar(context)

  init {
    barWithTimeCodesDuration.addView(timeBar)
    barWithTimeCodesDuration.addView(timeCodesDurationView)
    timeCodesDurationView.addView(timeCodesDuration)

    timeBar.viewTreeObserver.addOnGlobalLayoutListener {
      timeBarWidth = timeBar.width
    }
    visibility = INVISIBLE
    addView(barWithTimeCodesDuration)
  }

  override fun build(duration: Long) {
    timeBar.setDuration(duration)
    timeCodesDuration.text = helper.createTimeCodesFormatted(duration)
  }

  override fun update(position: Long, bufferProgress: Long) {
    timeBar.setPosition(position)
    timeBar.setBufferedPosition(bufferProgress)
    timeBar.requestLayout()
  }

  override fun onScrubListener(listener: OnScrubListener) {
    timeBar.addListener(listener)
  }

  override fun removeOnScrubListener(listener: OnScrubListener) {
    timeBar.removeListener(listener)
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

  private fun createTimeCodesDurationView(context: Context): FrameLayout {
    val timeCodesDurationView = FrameLayout(context).apply {
      layoutParams = LayoutParams(
        LayoutParams.WRAP_CONTENT,
        LayoutParams.WRAP_CONTENT
      ).apply {
        gravity = Gravity.CENTER
        setPadding(16, 16, 16, 16)
      }
    }
    return timeCodesDurationView
  }

  private fun createTimeCodesDuration(context: Context): TextView {
    return TextView(context).apply {
      setTextColor(ColorUtils.white)
      layoutParams = layoutParamsCenter(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
      text = context.getString(R.string.time_codes_start_value)
    }
  }
}
