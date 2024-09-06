package com.rnvideoplayer

import android.graphics.Color
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.view.WindowManager
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.facebook.react.common.MapBuilder
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.rnvideoplayer.helpers.MutableMapLongManager
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

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
    val events = listOf(
      "onMenuItemSelected",
      "onVideoProgress",
      "onLoaded",
      "onCompleted",
      "onReady",
      "onBuffer",
      "onBufferCompleted",
      "onPlayPause"
    )


    val mapBuilder = MapBuilder.builder<String, Any>()

    events.forEach { event ->
      mapBuilder.put(event, MapBuilder.of("registrationName", event))
    }

    return mapBuilder.build()
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
  @ReactProp(name = "menus")
  fun setMenus(rnVideoPlayerView: RNVideoPlayerView, menus: ReadableMap) {
    val menusData = mutableSetOf<String>()
    rnVideoPlayerView.getMenus(menus.toHashMap().keys)
    menus.entryIterator.forEach { i ->
      menusData.add(i.key)
      ReadableMapManager.getInstance().setReadableMapProps(i.value, i.key)
    }
    rnVideoPlayerView.getMenus(menusData)
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "startTime")
  fun setStartTime(player: RNVideoPlayerView, startTime: Double) {
    MutableMapLongManager.getInstance().setMutableMapProps(startTime, "startTime")
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "changeQualityUrl")
  fun setChangeQualityUrl(player: RNVideoPlayerView, changeQualityUrl: String) {
    if (changeQualityUrl.isNotEmpty()) {
      player.changeQuality(changeQualityUrl)
    }
  }

  private fun sendEvent(eventName: String, params: WritableMap) {
    reactApplicationContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      .emit(eventName, params)
  }
}

public object EventNames {
  const val menuItemSelected = "onMenuItemSelected"
  const val videoProgress = "onVideoProgress"
  const val videoLoaded = "onLoaded"
  const val videoCompleted = "onCompleted"
  const val videoReady = "onReady"
  const val videoBuffering = "onBuffer"
  const val videoBufferCompleted = "onBufferCompleted"
  const val videoPlayPauseStatus = "onPlayPause"
}
