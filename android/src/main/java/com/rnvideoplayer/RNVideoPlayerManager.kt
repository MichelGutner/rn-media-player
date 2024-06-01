package com.rnvideoplayer

import android.graphics.Color
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.view.WindowManager
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.rnvideoplayer.helpers.ReadableMapManager

var currentWidth: Int = 0;
var currentHeight: Int = 0;

class RNVideoPlayer : SimpleViewManager<View>() {
  override fun getName() = "RNVideoPlayer"

  @OptIn(UnstableApi::class)
  override fun createViewInstance(reactContext: ThemedReactContext): RNVideoPlayerView {
    val rnVideoPlayerView = RNVideoPlayerView(reactContext)
    rnVideoPlayerView.setBackgroundColor(Color.parseColor("black"))
    reactContext.currentActivity?.window?.setFlags(
      WindowManager.LayoutParams.FLAG_FULLSCREEN,
      WindowManager.LayoutParams.FLAG_FULLSCREEN
    )

    rnVideoPlayerView.viewTreeObserver.addOnGlobalLayoutListener(object :
      ViewTreeObserver.OnGlobalLayoutListener {
      override fun onGlobalLayout() {
        rnVideoPlayerView.viewTreeObserver.removeOnGlobalLayoutListener(this)
        currentHeight = rnVideoPlayerView.height
        currentWidth = rnVideoPlayerView.width
        (rnVideoPlayerView.parent as? ViewGroup)?.removeView(rnVideoPlayerView)

        (reactContext.currentActivity?.window?.decorView as? ViewGroup)?.addView(
          rnVideoPlayerView,
          ViewGroup.LayoutParams.MATCH_PARENT,
          currentHeight
        )
      }
    })

    return rnVideoPlayerView
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "source")
  fun setSource(rnVideoPlayerView: RNVideoPlayerView, source: ReadableMap?) {
    val url = source?.getString("url")
    if (!url.isNullOrEmpty()) {
      rnVideoPlayerView.setMediaItem(url)
    }
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "settings")
  fun setSettings(rnVideoPlayerView: RNVideoPlayerView, settings: ReadableMap) {
    rnVideoPlayerView.getSettingsProperties(settings)
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "qualities")
  fun setQualities(rnVideoPlayerView: RNVideoPlayerView, qualities: ReadableMap) {
    ReadableMapManager.getInstance().setReadableMapProps(qualities, "qualities")
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "speeds")
  fun setSpeeds(rnVideoPlayerView: RNVideoPlayerView, speeds: ReadableMap) {
    ReadableMapManager.getInstance().setReadableMapProps(speeds, "speeds")
  }

}
