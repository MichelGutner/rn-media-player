package com.rnvideoplayer.helpers

class MutableMapStringManager {
  private val storageObj = mutableMapOf<String, Any>()

  fun set(key: String, value: String) {
    println("key: $key, value: $value")
    storageObj[key] = value
  }

  fun get(key: String): Any? {
    println("keyGet: $key, value: ${storageObj}")
    return storageObj[key]
  }

  companion object {
    @Volatile
    private var instance: MutableMapStringManager? = null

    fun getInstance(): MutableMapStringManager {
      return instance ?: synchronized(this) {
        println("instance: $instance")
        instance ?: MutableMapStringManager().also { instance = it }
      }
    }
  }
}
