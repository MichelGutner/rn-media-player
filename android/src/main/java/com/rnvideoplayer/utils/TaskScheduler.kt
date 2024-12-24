package com.rnvideoplayer.utils

import android.os.Handler
import android.os.Looper

class TaskScheduler {
  private val handler = Handler(Looper.getMainLooper())
  private var runnable: Runnable? = null

  fun createTask(taskTime: Long = 1000, callback: () -> Unit) {
    cancelTask()
    runnable = Runnable {
      callback()
    }
    handler.postDelayed(runnable!!, taskTime)
  }
  fun cancelTask() {
    runnable?.let { handler.removeCallbacks(it) }
    runnable = null
  }
}
