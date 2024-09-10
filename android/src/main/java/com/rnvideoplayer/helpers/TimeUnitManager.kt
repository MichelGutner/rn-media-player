package com.rnvideoplayer.helpers

import java.util.concurrent.TimeUnit

class TimeUnitManager {
  fun toSecondsDouble(time: Long): Double {
    return TimeUnit.MILLISECONDS.toSeconds(time).toDouble()
  }
  fun toSecondsLong(time: Long): Long {
    return TimeUnit.MILLISECONDS.toSeconds(time)
  }
}
