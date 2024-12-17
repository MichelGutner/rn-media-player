package com.rnvideoplayer.mediaplayer.models

class ReactConfig {

  object Keys {
    const val DOUBLE_TAP_TO_SEEK_SUFFIX_LABEL = "suffixLabel"
    const val DOUBLE_TAP_TO_SEEK_VALUE = "doubleTapValue"

    val allowedKeys = setOf(
      DOUBLE_TAP_TO_SEEK_SUFFIX_LABEL,
      DOUBLE_TAP_TO_SEEK_VALUE
    )
  }

  private val config: MutableMap<String, Any> = mutableMapOf()

  fun set(key: String, value: Any) {
    if (key in Keys.allowedKeys) {
      println("key: $key  value: $value")
      config[key] = value
    } else {
      throw IllegalArgumentException("Key '$key' not acepted. use only ReactConfig.Keys.")
    }
  }

  fun get(key: String): Any? {
    return config[key]
  }

  companion object {
    @Volatile
    private var instance: ReactConfig? = null

    fun getInstance(): ReactConfig {
      return instance ?: synchronized(this) {
        println("instance: $instance  ")
        instance ?: ReactConfig().also { instance = it }
      }
    }
  }
}
