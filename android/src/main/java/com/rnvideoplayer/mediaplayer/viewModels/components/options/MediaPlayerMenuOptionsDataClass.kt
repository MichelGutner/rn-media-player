package com.rnvideoplayer.mediaplayer.viewModels.components.options

import com.facebook.react.bridge.ReadableArray

data class MediaPlayerMenuOptionsDataClass(
  val name: String,
  val value: ReadableArray?,
  val parentName: String,
  var optionSelected: String? = null
)

data class OptionItem(val name: String, val value: Any)
