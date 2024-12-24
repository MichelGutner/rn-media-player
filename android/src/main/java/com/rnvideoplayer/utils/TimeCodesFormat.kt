package com.rnvideoplayer.utils

import android.annotation.SuppressLint
import java.util.concurrent.TimeUnit

class TimeCodesFormat {
  @SuppressLint("DefaultLocale")
  fun format(time: Long): String {
    val hours = TimeUnit.MILLISECONDS.toHours(time)
    val minutes = TimeUnit.MILLISECONDS.toMinutes(time)
    val seconds = TimeUnit.MILLISECONDS.toSeconds(time) - TimeUnit.MINUTES.toSeconds(minutes)

    return if (hours > 0) {
      String.format("%02d:%02d:%02d", minutes, seconds)
    } else {
      String.format("%02d:%02d", minutes, seconds)
    }
  }
}
