package com.rnvideoplayer.interfaces

import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.TimeBar

@OptIn(UnstableApi::class)
interface ICustomSeekBar {
  fun build(duration: Long)
  fun update(position: Long, bufferProgress: Long)
  fun onScrubListener(listener: TimeBar.OnScrubListener)
  fun removeOnScrubListener(listener: TimeBar.OnScrubListener)
}
