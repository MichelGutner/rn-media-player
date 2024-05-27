package com.rnvideoplayer.interfaces

import androidx.media3.ui.TimeBar

interface ICustomSeekBar {
  fun build(duration: Long)
  fun update(position: Long, bufferProgress: Long)
  fun onScrubListener(listener: TimeBar.OnScrubListener)
  fun removeOnScrubListener(listener: TimeBar.OnScrubListener)
}
