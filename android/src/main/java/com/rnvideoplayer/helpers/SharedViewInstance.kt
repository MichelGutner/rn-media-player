package com.rnvideoplayer.helpers

import androidx.media3.ui.PlayerView

class SharedViewInstance {
  companion object {
    private val instanceMap: MutableMap<String, PlayerView> = mutableMapOf()
    fun getViewInstance(key: String): PlayerView {
      return instanceMap[key] as PlayerView
    }

    fun registerView(key: String, instance: PlayerView) {
      instanceMap[key] = instance
    }

    fun unregisterView(key: String) {
      instanceMap.remove(key)
    }
  }
}
