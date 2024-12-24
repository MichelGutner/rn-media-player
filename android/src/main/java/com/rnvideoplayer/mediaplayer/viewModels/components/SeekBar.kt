package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.AttributeSet
import android.view.Gravity
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.DefaultTimeBar
import androidx.media3.ui.TimeBar
import androidx.media3.ui.TimeBar.OnScrubListener
import com.rnvideoplayer.interfaces.ICustomSeekBar

@UnstableApi
class SeekBar(context: Context) : LinearLayout(context), ICustomSeekBar {
  private var timeBarWidth: Int = 0
    private set

  private val seekBar = seekBarWrapper(context)
  var isSeeking = false

  init {
    seekBar.viewTreeObserver.addOnGlobalLayoutListener {
      timeBarWidth = seekBar.width
    }
    addView(seekBar)
    gravity = Gravity.BOTTOM

    seekBar.addListener(object : OnScrubListener {
      override fun onScrubStart(timeBar: TimeBar, position: Long) {
        isSeeking = true
      }

      override fun onScrubMove(timeBar: TimeBar, position: Long) {}

      override fun onScrubStop(timeBar: TimeBar, position: Long, canceled: Boolean) {
        isSeeking =  false
      }
    })
  }

  override fun build(duration: Long) {
    seekBar.setDuration(duration)
  }

  override fun update(position: Long, bufferProgress: Long) {
    seekBar.setPosition(position)
    seekBar.setBufferedPosition(bufferProgress)
    seekBar.requestLayout()
  }

  override fun onScrubListener(listener: OnScrubListener) {
    seekBar.addListener(listener)
  }

  override fun removeOnScrubListener(listener: OnScrubListener) {
    seekBar.removeListener(listener)
  }

  private fun seekBarWrapper(context: Context): DefaultTimeBar {
    return CustomDefaultTimeBar(context).apply {
      setScrubberColor(Color.TRANSPARENT)
      layoutParams = LayoutParams(
        0,
        50
      ).apply {
        weight = 1f
        gravity = Gravity.BOTTOM
      }
    }
  }
}

@OptIn(UnstableApi::class)
class CustomDefaultTimeBar(context: Context, attrs: AttributeSet? = null) :
  DefaultTimeBar(context, attrs) {

  init {
    val barHeightField = DefaultTimeBar::class.java.getDeclaredField("barHeight")
    barHeightField.isAccessible = true
    barHeightField.set(this, dpToPx(10))

    val scrubberSizeField = DefaultTimeBar::class.java.getDeclaredField("scrubberEnabledSize")
    scrubberSizeField.isAccessible = true
    scrubberSizeField.set(this, dpToPx(15))
  }

  private fun dpToPx(dp: Int): Int {
    return (dp * resources.displayMetrics.density).toInt()
  }
}
