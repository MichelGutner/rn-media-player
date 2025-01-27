package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.graphics.Color
import android.util.AttributeSet
import android.view.Gravity
import android.widget.LinearLayout
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.DefaultTimeBar
import androidx.media3.ui.TimeBar
import androidx.media3.ui.TimeBar.OnScrubListener

@OptIn(UnstableApi::class)
private interface ICustomSeekBar {
  fun setDuration(duration: Long)
  fun setPosition(position: Long, bufferProgress: Long)
  fun onScrubListener(listener: OnScrubListener)
  fun removeOnScrubListener(listener: OnScrubListener)
}

@UnstableApi
class SeekBar(context: Context) : LinearLayout(context), ICustomSeekBar {
  private var timeBarWidth: Int = 0

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

  override fun setDuration(duration: Long) {
    seekBar.setDuration(duration)
  }

  override fun setPosition(position: Long, bufferProgress: Long) {
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
      setUnplayedColor(Color.argb(30,255,255,255))
      setBufferedColor(Color.argb(80,255,255,255))
      layoutParams = LayoutParams(
        0,
        70
      ).apply {
        weight = 1f
        gravity = Gravity.BOTTOM
      }
      requestLayout()
    }
  }
}

@OptIn(UnstableApi::class)
class CustomDefaultTimeBar(context: Context, attrs: AttributeSet? = null) :
  DefaultTimeBar(context, attrs) {

  init {
    configureBarDimensions()
  }

  private fun configureBarDimensions() {
    setPrivateField("barHeight", dpToPx(4))
    setPrivateField("scrubberEnabledSize", dpToPx(25))
  }

  private fun setPrivateField(fieldName: String, value: Int) {
    try {
      val field = DefaultTimeBar::class.java.getDeclaredField(fieldName)
      field.isAccessible = true
      field.set(this, value)
    } catch (e: Exception) {
      e.printStackTrace()
    }
  }

  private fun dpToPx(dp: Int): Int {
    return (dp * resources.displayMetrics.density).toInt()
  }
}
