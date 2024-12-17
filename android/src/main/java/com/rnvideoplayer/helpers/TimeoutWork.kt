package com.rnvideoplayer.helpers

import java.util.Timer
import java.util.TimerTask

class TimeoutWork {
  private var timer = Timer()
  private var resetTimerTask: TimerTask? = null

  fun createTask(resetDuration: Long = 1000, callback: () -> Unit) {
    resetTimerTask = object : TimerTask() {
      override fun run() {
        callback()
      }
    }
    timer.schedule(resetTimerTask, resetDuration)
  }
  fun cancelTimer() {
    resetTimerTask?.cancel()
  }
}
