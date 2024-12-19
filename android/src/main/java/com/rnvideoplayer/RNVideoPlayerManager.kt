package com.rnvideoplayer

import android.view.View
import androidx.annotation.OptIn
import androidx.media3.common.MediaMetadata
import androidx.media3.common.util.UnstableApi
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.rnvideoplayer.mediaplayer.models.ReactConfig
import com.rnvideoplayer.mediaplayer.models.ReactEventsName
import com.rnvideoplayer.mediaplayer.views.MediaPlayerView

class RNVideoPlayer : SimpleViewManager<View>() {
  override fun getName() = "RNVideoPlayer"

  @OptIn(UnstableApi::class)
  override fun createViewInstance(reactContext: ThemedReactContext): MediaPlayerView {
    return MediaPlayerView(reactContext)
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
    val mapBuilder = MapBuilder.builder<String, Any>()
    ReactEventsName.registeredEvents.forEach { event ->
      mapBuilder.put(event, MapBuilder.of("registrationName", event))
    }

    return mapBuilder.build()
  }

//  @OptIn(UnstableApi::class)
//  @ReactProp(name = "resizeMode")
//  fun setResizeMode(rnVideoPlayerView: RNVideoPlayerView, resizeMode: String) {
//    val resizeModeValue = when (resizeMode) {
//      "contain" -> 1.5
//      "cover" -> 0
//      else -> 1.5
//    }
//    rnVideoPlayerView.changeResizeMode(resizeModeValue.toFloat())
//  }
//
//  @OptIn(UnstableApi::class)
//  @ReactProp(name = "screenBehavior")
//  fun setScreenBehavior(rnVideoPlayerView: RNVideoPlayerView, screenBehavior: ReadableMap?) {
//    SharedStore.getInstance().putBoolean("autoEnterFullscreenOnLandscape", screenBehavior?.getBoolean("autoEnterFullscreenOnLandscape") ?: false)
//    SharedStore.getInstance().putBoolean("autoOrientationOnFullscreen", screenBehavior?.getBoolean("autoOrientationOnFullscreen") ?: false)
//  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "source")
  fun setSource(view: MediaPlayerView, source: ReadableMap?) {
    val url = source?.getString("url") as String
    val startTime = source.getDouble("startTime")
    val metadata = source.getMap("metadata")

    val longStartTime = if (startTime == 0.0) 0 else (startTime * 1000).toLong()
    val mediaMetadata = MediaMetadata.Builder()
      .setTitle(metadata?.getString("title"))
      .setArtist(metadata?.getString("artist"))
      .build()

    view.setupMediaPlayer(url, longStartTime, mediaMetadata)
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "thumbnails")
  fun setThumbnails(view: MediaPlayerView, thumbnails: ReadableMap?) {
    if (thumbnails != null) {
      val sourceUrl = thumbnails.getString("sourceUrl") as String
      val enabled = thumbnails.getBoolean("isEnabled")
      if (enabled) {
        if (sourceUrl.isNotEmpty()) {
          view.startDownloadThumbnailFrames(sourceUrl)
        }
      }
    }
  }
//
  @OptIn(UnstableApi::class)
  @ReactProp(name = "rate")
  fun setRate(view: MediaPlayerView, rate: Double) {
    view.onChangePlaybackSpeed(rate.toFloat())
  }
////
  @OptIn(UnstableApi::class)
  @ReactProp(name = "autoPlay")
  fun setAutoPlay(view: MediaPlayerView, value: Boolean) {
    view.onAutoPlay(value)
  }
@OptIn(UnstableApi::class)
@ReactProp(name = "menus")
fun setMenus(view: MediaPlayerView, menus: ReadableMap) {
  val reactConfig = ReactConfig.getInstance()

  menus.entryIterator.forEach { entry ->
    reactConfig.set(entry.key, entry.value)
  }
  reactConfig.set(ReactConfig.Key.MENU_ITEMS, menus.toHashMap().keys)

}

  @OptIn(UnstableApi::class)
  @ReactProp(name = "doubleTapToSeek")
  fun setSuffixLabelTapToSeek(view: MediaPlayerView, doubleTapToSeek: ReadableMap?) {
    if (doubleTapToSeek == null) return
    val reactConfig = ReactConfig.getInstance()
  if (doubleTapToSeek.hasKey("suffixLabel") && doubleTapToSeek.getType("suffixLabel") == ReadableType.String) {
    val suffixLabel = doubleTapToSeek.getString("suffixLabel") as String
    reactConfig.set(ReactConfig.Key.DOUBLE_TAP_TO_SEEK_SUFFIX_LABEL, suffixLabel)
  }
  if (doubleTapToSeek.hasKey("value") && doubleTapToSeek.getType("value") == ReadableType.Number) {
    val value = doubleTapToSeek.getDouble("value")
    reactConfig.set(ReactConfig.Key.DOUBLE_TAP_TO_SEEK_VALUE, value.toInt())
  }
    view.addReactConfigs(reactConfig)
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "replaceMediaUrl")
  fun setReplaceMediaUrl(view: MediaPlayerView, replaceMediaUrl: String) {
    if (replaceMediaUrl.isNotEmpty()) {
      view.onReplaceMedia(replaceMediaUrl)
    }
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "entersFullScreenWhenPlaybackBegins")
  fun setEntersFullScreenWhenPlaybackBegins(view: MediaPlayerView, entersFullScreenWhenPlaybackBegins: Boolean) {
    val reactConfig = ReactConfig.getInstance()
    reactConfig.set(ReactConfig.Key.ENTERS_FULL_SCREEN_WHEN_PLAYBACK_BEGINS, entersFullScreenWhenPlaybackBegins)
  }
}

fun View.fadeIn(duration: Long = 300, completion: () -> Unit = {}) {
  this.post {
    this.visibility = View.VISIBLE
    this.alpha = 0f
    this.animate()
      .alpha(1f)
      .withEndAction { completion.invoke() }
      .setDuration(duration)
      .setListener(null)
  }
}

fun View.fadeOut(duration: Long = 300, completion: (() -> Unit)? = null) {
  post {
    animate()
      .alpha(0f)
      .setDuration(duration)
      .withEndAction {
        visibility = View.INVISIBLE
        completion?.invoke()
      }
  }
}

fun View.withTranslationAnimation(translationY: Float? = 0f, duration: Long? = 300) {
  this.post {
    animate()
      .translationY(translationY!!)
      .setDuration(duration!!)
      .start()
  }
}
