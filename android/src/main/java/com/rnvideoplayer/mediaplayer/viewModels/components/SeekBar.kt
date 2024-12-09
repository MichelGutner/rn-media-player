package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.view.Gravity
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.DefaultTimeBar
import androidx.media3.ui.TimeBar.OnScrubListener
import com.rnvideoplayer.interfaces.ICustomSeekBar

@UnstableApi
class SeekBar(context: Context) : LinearLayout(context), ICustomSeekBar {
  var timeBarWidth: Int = 0
    private set

  private val seekBar = seekBarWrapper(context)

  init {
    seekBar.viewTreeObserver.addOnGlobalLayoutListener {
      timeBarWidth = seekBar.width
    }
    addView(seekBar)
    gravity = Gravity.BOTTOM
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
    return DefaultTimeBar(context).apply {
      layoutParams = LayoutParams(
        0,
        ViewGroup.LayoutParams.WRAP_CONTENT
      ).apply {
        weight = 1f
        gravity = Gravity.BOTTOM
      }
    }
  }
}
