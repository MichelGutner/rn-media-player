package com.rnvideoplayer.helpers

import com.facebook.react.bridge.ReadableNativeMap

class ReadableMapManager {
  private val map: MutableMap<String, Any> = mutableMapOf()

  fun setReadableMapProps(readableMap: Any, key: String) {
    map[key] = readableMap
  }

  fun getReadableMapProps(key: String): ReadableNativeMap {
    return map[key] as ReadableNativeMap
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
