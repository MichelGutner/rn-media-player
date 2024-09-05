package com.rnvideoplayer.helpers

import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableNativeArray
import com.rnvideoplayer.components.CustomContentDialog

class ReadableMapManager {
  private val map: MutableMap<String, Any> = mutableMapOf()

  fun setReadableMapProps(readableMap: Any, key: String) {
    map[key] = readableMap
  }

  fun getReadableMapProps(key: String): ReadableNativeArray {
    return map[key] as ReadableNativeArray
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
