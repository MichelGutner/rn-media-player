package com.rnvideoplayer

import android.graphics.Color
import android.view.View
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp

class RNVideoPlayer : SimpleViewManager<View>() {
  override fun getName() = "RNVideoPlayer"

  override fun createViewInstance(reactContext: ThemedReactContext): CustomPlayer {
    val customPlayer = CustomPlayer(reactContext)
    customPlayer.setBackgroundColor(Color.parseColor("black"))

    return customPlayer
  }

  @ReactProp(name = "source")
  fun setSource(customPlayer: CustomPlayer, source: ReadableMap?) {
    val url = source?.getString("url")
    if (!url.isNullOrEmpty()) {
        customPlayer.setMediaItem(url)
    }
  }
}
