package com.rnvideoplayer
import android.graphics.Color
import android.net.Uri
import android.view.View
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.SimpleExoPlayer
import com.google.android.exoplayer2.ui.PlayerView

class RNVideoPlayer : SimpleViewManager<View>() {
    private var exoPlayer: SimpleExoPlayer? = null
  override fun getName() = "RNVideoPlayer"

  override fun createViewInstance(reactContext: ThemedReactContext): PlayerView {
    var playerView =  PlayerView(reactContext)
    initializePlayer(reactContext, playerView)
    return playerView
  }

  @ReactProp(name = "color")
  fun setColor(view: View, color: String) {
    view.setBackgroundColor(Color.parseColor(color))
  }

  private fun initializePlayer(context: ThemedReactContext, playerView: PlayerView) {
    if (exoPlayer == null) {
      exoPlayer = SimpleExoPlayer.Builder(context).build()
    }

    playerView.player = exoPlayer
  }

  @ReactProp(name = "source")
  fun setSource(playerView: PlayerView, source: ReadableMap?) {
    val url = source?.getString("url")
    if (!url.isNullOrEmpty()) {
      val uri = Uri.parse(url)
      val mediaSource = MediaItem.fromUri(url)
      playerView.player?.addMediaItem(mediaSource)
      playerView.hideController()
      playerView.player?.prepare()
      playerView.player?.play()
    }
  }
}

