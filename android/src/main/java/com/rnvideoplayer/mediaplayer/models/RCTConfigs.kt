package com.rnvideoplayer.mediaplayer.models

class RCTConfigs {
  object Key {
    const val DOUBLE_TAP_TO_SEEK_SUFFIX_LABEL = "suffixLabel"
    const val DOUBLE_TAP_TO_SEEK_VALUE = "doubleTapValue"
    const val MENU_ITEMS = "menuItems"
    const val ENTERS_FULL_SCREEN_WHEN_PLAYBACK_BEGINS = "enterFullScreenWhenPlaybackBegins"
  }

  private val config: MutableMap<String, Any> = mutableMapOf()

  fun set(key: String, value: Any) {
      config[key] = value
  }

  fun get(key: String): Any? {
    return config[key]
  }

  companion object {
    @Volatile
    private var instance: RCTConfigs? = null

    fun getInstance(): RCTConfigs {
      return instance ?: synchronized(this) {
        instance ?: RCTConfigs().also { instance = it }
      }
    }
  }
}
