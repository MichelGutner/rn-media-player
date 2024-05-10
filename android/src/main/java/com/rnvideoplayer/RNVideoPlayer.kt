package com.rnvideoplayer

import android.graphics.Color
import android.os.Build
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp

var currentWidth: Int = 0;
var currentHeight: Int = 0;

class RNVideoPlayer : SimpleViewManager<View>() {
  private var statusBarColor: Int = Color.TRANSPARENT
  override fun getName() = "RNVideoPlayer"

  @OptIn(UnstableApi::class) override fun createViewInstance(reactContext: ThemedReactContext): CustomPlayer {
    val customPlayer = CustomPlayer(reactContext)
    customPlayer.setBackgroundColor(Color.parseColor("black"))
    statusBarColor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      reactContext.currentActivity?.window?.statusBarColor ?: Color.TRANSPARENT
    } else {
      Color.TRANSPARENT
    }
    customPlayer.systemUiVisibility = (View.SYSTEM_UI_FLAG_FULLSCREEN
            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)

    customPlayer.viewTreeObserver.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
      override fun onGlobalLayout() {
        customPlayer.viewTreeObserver.removeOnGlobalLayoutListener(this)
        currentHeight = customPlayer.height
        currentWidth= customPlayer.width
        (customPlayer.parent as? ViewGroup)?.removeView(customPlayer)

        (reactContext.currentActivity?.window?.decorView as? ViewGroup)?.addView(
          customPlayer,
          ViewGroup.LayoutParams.MATCH_PARENT,
          currentHeight
        )
      }
    })

    return customPlayer
  }

  @OptIn(UnstableApi::class) @ReactProp(name = "source")
  fun setSource(customPlayer: CustomPlayer, source: ReadableMap?) {
    val url = source?.getString("url")
    if (!url.isNullOrEmpty()) {
      customPlayer.setMediaItem(url)
    }
  }
}
