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
import com.rnvideoplayer.mediaplayer.logger.Debug
import com.rnvideoplayer.mediaplayer.models.RCTConfigs
import com.rnvideoplayer.mediaplayer.models.RCTEvents
import com.rnvideoplayer.mediaplayer.views.MediaPlayerView

class RNVideoPlayer : SimpleViewManager<View>() {
  override fun getName() = "RNVideoPlayer"

  @OptIn(UnstableApi::class)
  override fun createViewInstance(reactContext: ThemedReactContext): MediaPlayerView {
    return MediaPlayerView(reactContext)
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
    val mapBuilder = MapBuilder.builder<String, Any>()
    RCTEvents.registered.forEach { event ->
      mapBuilder.put(event, MapBuilder.of("registrationName", event))
    }

    return mapBuilder.build()
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "source")
  fun setSource(view: MediaPlayerView, source: ReadableMap?) {
    var startTime = 0.0
    if (source?.hasKey("startTime") == true) {
      startTime = source.getDouble("startTime")
      Debug.log("startTime: $startTime")
    }
    val metadata = source?.getMap("metadata")

    val url = source?.getString("url") as String

    val longStartTime = (startTime * 1000).toLong()
    val mediaMetadata = MediaMetadata.Builder()
      .setTitle(metadata?.getString("title") ?: "")
      .setArtist(metadata?.getString("artist") ?: "")
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
          view.shouldExecuteDownloadThumbnailFrames(sourceUrl)
        }
      }
    }
  }

  //
  @OptIn(UnstableApi::class)
  @ReactProp(name = "rate")
  fun setRate(view: MediaPlayerView, rate: Double) {
    if (rate.isFinite()) {
      view.onChangePlaybackSpeed(rate.toFloat())
    }
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "autoPlay")
  fun setAutoPlay(view: MediaPlayerView, value: Boolean) {
    view.onAutoPlay(value)
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "menus")
  fun setMenus(view: MediaPlayerView, menus: ReadableMap?) {
    if (menus != null) {
      val reactConfigAdapter = RCTConfigs.getInstance()

      menus.entryIterator.forEach { entry ->
        reactConfigAdapter.set(entry.key, entry.value)
      }
      reactConfigAdapter.set(RCTConfigs.Key.MENU_ITEMS, menus.toHashMap().keys)
    }
  }

  @OptIn(UnstableApi::class)
  @ReactProp(name = "doubleTapToSeek")
  fun setSuffixLabelTapToSeek(view: MediaPlayerView, doubleTapToSeek: ReadableMap?) {
    if (doubleTapToSeek == null) return
    val reactConfigAdapter = RCTConfigs.getInstance()
    if (doubleTapToSeek.hasKey("suffixLabel") && doubleTapToSeek.getType("suffixLabel") == ReadableType.String) {
      val suffixLabel = doubleTapToSeek.getString("suffixLabel") as String
      reactConfigAdapter.set(RCTConfigs.Key.DOUBLE_TAP_TO_SEEK_SUFFIX_LABEL, suffixLabel)
    }
    if (doubleTapToSeek.hasKey("value") && doubleTapToSeek.getType("value") == ReadableType.Number) {
      val value = doubleTapToSeek.getDouble("value")
      reactConfigAdapter.set(RCTConfigs.Key.DOUBLE_TAP_TO_SEEK_VALUE, value.toInt())
    }
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
  fun setEntersFullScreenWhenPlaybackBegins(
    view: MediaPlayerView,
    entersFullScreenWhenPlaybackBegins: Boolean
  ) {
    val reactConfigAdapter = RCTConfigs.getInstance()
    reactConfigAdapter.set(
      RCTConfigs.Key.ENTERS_FULL_SCREEN_WHEN_PLAYBACK_BEGINS,
      entersFullScreenWhenPlaybackBegins
    )
  }
}
