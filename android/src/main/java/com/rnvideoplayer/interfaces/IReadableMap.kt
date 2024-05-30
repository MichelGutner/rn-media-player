package com.rnvideoplayer.interfaces

import com.facebook.react.bridge.ReadableMap

val ReadableMap.name: String
  get() {
    return this.getString("name").toString()
  }

val ReadableMap.value: String
  get() {
    return this.getString("value").toString()
  }

val ReadableMap.enabled: Boolean
  get() {
    return this.getBoolean("enabled")
  }
