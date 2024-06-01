package com.rnvideoplayer.helpers

import com.facebook.react.bridge.ReadableMap

class ReadableMapManager {
  private val map: MutableMap<String, ReadableMap> = mutableMapOf()

  fun setReadableMapProps(readableMap: ReadableMap, key: String) {
    map[key] = readableMap
  }

  fun getReadableMapProps(key: String): ReadableMap? {
    return map[key]
  }

  companion object {
    @Volatile
    private var instance: ReadableMapManager? = null
    fun getInstance(): ReadableMapManager {
      if (instance == null) {
        instance = ReadableMapManager()
      }
      return instance!!
    }
  }
}
