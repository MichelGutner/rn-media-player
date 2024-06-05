package com.rnvideoplayer.helpers

class MutableMapLongManager {
  private val map = mutableMapOf<String, Long>()
  fun getMutableMapProps(key: String): Long? {
    return map[key]
  }
  fun setMutableMapProps(value: Double, key: String) {
    map[key] = value.toLong()
  }

  companion object {
    @Volatile
    private var instance: MutableMapLongManager? = null

    fun getInstance(): MutableMapLongManager {
      return instance ?: synchronized(this) {
        instance ?: MutableMapLongManager().also { instance = it }
      }
    }
  }
}
