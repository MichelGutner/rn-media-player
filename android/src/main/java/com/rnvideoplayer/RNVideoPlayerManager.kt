package com.rnvideoplayer

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.annotation.SuppressLint
import android.graphics.Color
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.view.WindowManager
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.rnvideoplayer.events.events
import com.rnvideoplayer.helpers.ReadableMapManager
import com.rnvideoplayer.helpers.SharedStore
import com.rnvideoplayer.helpers.SharedStoreKey
import com.rnvideoplayer.helpers.SharedViewInstance

class RNVideoPlayer : SimpleViewManager<View>() {
  override fun getName() = "RNVideoPlayer"

  @OptIn(UnstableApi::class)
  override fun createViewInstance(reactContext: ThemedReactContext): RNVideoPlayerViewX {
    val rnVideoPlayerView = RNVideoPlayerViewX(reactContext)

    return rnVideoPlayerView
  }


  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
    val mapBuilder = MapBuilder.builder<String, Any>()
    events.forEach { event ->
      mapBuilder.put(event, MapBuilder.of("registrationName", event))
    }

    return mapBuilder.build()
  }


//  @OptIn(UnstableApi::class)
//  @ReactProp(name = "resizeMode")
//  fun setResizeMode(rnVideoPlayerView: CustomExoPlayerView, resizeMode: String) {
//    val resizeModeInt = when (resizeMode) {
//      "contain" -> AspectRatioFrameLayout.RESIZE_MODE_FIT
//      "cover" -> AspectRatioFrameLayout.RESIZE_MODE_FILL
//      else -> AspectRatioFrameLayout.RESIZE_MODE_FIT
//    }
//    rnVideoPlayerView.setResizeMode(resizeModeInt)
//  }

//  @OptIn(UnstableApi::class)
//  @ReactProp(name = "source")
//  fun setSource(rnVideoPlayerView: RNVideoPlayerView, source: ReadableMap?) {
//      rnVideoPlayerView.mediaPlayer.build(source)
//  }
//
//  @OptIn(UnstableApi::class)
//  @ReactProp(name = "rate")
//  fun setRate(rnVideoPlayerView: RNVideoPlayerView, rate: Double) {
//    rnVideoPlayerView.changeRate(rate.toFloat())
//  }
//
//  @OptIn(UnstableApi::class)
//  @ReactProp(name = "autoPlay")
//  fun setAutoPlay(rnVideoPlayerView: RNVideoPlayerView, autoPlay: Boolean) {
//    rnVideoPlayerView.mediaPlayer.autoPlay(autoPlay)
//  }
//
//  @OptIn(UnstableApi::class)
//  @ReactProp(name = "menus")
//  fun setMenus(rnVideoPlayerView: RNVideoPlayerView, menus: ReadableMap) {
//    val menusData = mutableSetOf<String>()
//    rnVideoPlayerView.getMenus(menus.toHashMap().keys)
//    menus.entryIterator.forEach { i ->
//      menusData.add(i.key)
//      ReadableMapManager.getInstance().setReadableMapProps(i.value, i.key)
//    }
//    rnVideoPlayerView.getMenus(menusData)
//  }
//
//  @OptIn(UnstableApi::class)
//  @ReactProp(name = "tapToSeek")
//  fun setSuffixLabelTapToSeek(player: RNVideoPlayerView, tapToSeek: ReadableMap?) {
//    val suffixLabel = tapToSeek?.getString("suffixLabel")
//    val value = tapToSeek?.getDouble("value")
//    if (suffixLabel != null) {
//      SharedStore.getInstance().putString(SharedStoreKey.SUFFIX_LABEL, suffixLabel)
//    }
//    if (value != null) {
//      SharedStore.getInstance().putLong(SharedStoreKey.DOUBLE_TAP_VALUE, value.toLong())
//    }
//  }
//
//  @OptIn(UnstableApi::class)
//  @ReactProp(name = "changeQualityUrl")
//  fun setChangeQualityUrl(player: RNVideoPlayerView, changeQualityUrl: String) {
//    if (changeQualityUrl.isNotEmpty()) {
//      player.changeQuality(changeQualityUrl)
//    }
//  }
}

object EventNames {
  const val menuItemSelected = "onMenuItemSelected"
  const val videoProgress = "onVideoProgress"
  const val videoLoaded = "onLoaded"
  const val videoCompleted = "onCompleted"
  const val videoReady = "onReady"
  const val videoBuffering = "onBuffer"
  const val videoPlayPauseStatus = "onPlayPause"
  const val videoErrorStatus = "onError"
}

fun View.fadeIn(duration: Long = 500) {
  this.post {
    this.visibility = View.VISIBLE
    this.alpha = 0f
    this.animate()
      .alpha(1f)
      .setDuration(duration)
      .setListener(null)
  }
}

fun View.fadeOut(duration: Long = 500, completion: (() -> Unit)? = null) {
  this.post {
    this.animate()
      .alpha(0f)
      .setDuration(duration)
      .setListener(object : AnimatorListenerAdapter() {
        override fun onAnimationEnd(animation: Animator) {
          this@fadeOut.visibility = View.INVISIBLE
          completion.also {
            it?.invoke()
          }
        }
      })
  }
}
