package com.rnvideoplayer.helpers

class SharedStore {
  private val stringMap = mutableMapOf<String, Any>()

  fun putString(key: String, value: String) {
    stringMap[key] = value
  }

  fun getString(key: String): String? {
    return stringMap[key] as? String
  }

  fun putDouble(key: String, value: Double) {
    stringMap[key] = value
  }

  fun getDouble(key: String): Double? {
    return stringMap[key] as? Double
  }

  fun putLong(key: String, value: Long) {
    stringMap[key] = value
  }

  fun getLong(key: String): Long? {
    return stringMap[key] as? Long
  }

  companion object {
    @Volatile
    private var instance: SharedStore? = null

    fun getInstance(): SharedStore {
      return instance ?: synchronized(this) {
        instance ?: SharedStore().also { instance = it }
      }
    }
  }
}

object SharedStoreKey {
  const val SUFFIX_LABEL = "suffixLabel"
  const val DOUBLE_TAP_VALUE = "doubleTapValue"
}
