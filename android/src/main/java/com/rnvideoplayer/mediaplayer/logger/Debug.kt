package com.rnvideoplayer.mediaplayer.logger

import android.util.Log

class Debug {
  companion object {
    fun log(message: String) {
      Log.d("Debug MediaPlayer", message)
    }
  }
}
