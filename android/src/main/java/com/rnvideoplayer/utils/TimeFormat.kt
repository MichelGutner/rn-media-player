package com.rnvideoplayer.utils

import android.annotation.SuppressLint
import java.util.concurrent.TimeUnit

class TimeFormat {
  @SuppressLint("DefaultLocale")
  fun format(time: Long): String {
    val hours = TimeUnit.MILLISECONDS.toHours(time)
    val minutes = TimeUnit.MILLISECONDS.toMinutes(time) - TimeUnit.HOURS.toMinutes(hours)
    val seconds = TimeUnit.MILLISECONDS.toSeconds(time) - TimeUnit.MINUTES.toSeconds(TimeUnit.MILLISECONDS.toMinutes(time))

    return if (hours > 0) {
      String.format("%02d:%02d:%02d", hours, minutes, seconds)
    } else {
      String.format("%02d:%02d", minutes, seconds)
    }
  }
}
