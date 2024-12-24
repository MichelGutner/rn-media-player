package com.rnvideoplayer.utils

import java.util.concurrent.TimeUnit

class TimeUnitFormat {
  fun toSecondsDouble(time: Long): Double {
    return TimeUnit.MILLISECONDS.toSeconds(time).toDouble()
  }
}
