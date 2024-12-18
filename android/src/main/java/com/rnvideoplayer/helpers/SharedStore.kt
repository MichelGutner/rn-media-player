package com.rnvideoplayer.helpers

class SharedStore {
  private val stringMap = mutableMapOf<String, Any>()

  fun putString(key: String, value: String) {
    stringMap[key] = value
  }

  fun getString(key: String): String? {
    return stringMap[key] as? String
  }

  fun putLong(key: String, value: Long) {
    stringMap[key] = value
  }

  fun getLong(key: String): Long? {
    return stringMap[key] as? Long
  }

  fun putBoolean(key: String, value: Boolean) {
    stringMap[key] = value
  }

  fun getBoolean(key: String): Boolean? {
    return stringMap[key] as? Boolean
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
