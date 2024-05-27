package com.rnvideoplayer.components

import android.view.View
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.DefaultTimeBar
import androidx.media3.ui.TimeBar.OnScrubListener
import com.rnvideoplayer.R
import com.rnvideoplayer.interfaces.ICustomSeekBar

@UnstableApi
class CustomSeekBar(view: View) : ICustomSeekBar {
  private val timeBar = view.findViewById<DefaultTimeBar>(R.id.time_bar)
  var width: Int = 0
    private set

  init {
    timeBar.viewTreeObserver.addOnGlobalLayoutListener {
      width = timeBar.width
    }
  }

  override fun build(duration: Long) {
    timeBar.setDuration(duration)
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
}
