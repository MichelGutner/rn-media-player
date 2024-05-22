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
    rnVideoPlayerView.systemUiVisibility = (View.SYSTEM_UI_FLAG_FULLSCREEN
      or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
      or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)

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
  fun setSource(RNVideoPlayerView: RNVideoPlayerView, source: ReadableMap?) {
    val url = source?.getString("url")
    if (!url.isNullOrEmpty()) {
      RNVideoPlayerView.setMediaItem(url)
    }
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "settings")
  fun setSettings(rnVideoPlayerView: RNVideoPlayerView, settings: ReadableMap) {
    rnVideoPlayerView.getSettingsProperties(settings)
  }

}
