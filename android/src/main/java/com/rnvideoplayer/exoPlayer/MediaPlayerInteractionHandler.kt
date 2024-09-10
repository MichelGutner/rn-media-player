package com.rnvideoplayer.exoPlayer

import android.net.Uri
import android.view.LayoutInflater
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.PlayerView
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R

@UnstableApi
class MediaPlayerInteractionHandler(private val context: ThemedReactContext, private val view: PlayerView) {
  val exoPlayer: ExoPlayer = ExoPlayer.Builder(context).build()
  var thumbnailUrl: String = ""

  init {
    inflateLayout()
  }

  private fun inflateLayout() {
    val inflater = LayoutInflater.from(context)
    inflater.inflate(R.layout.custom_player, view, true)
  }

  fun autoPlay(autoPlay: Boolean = true) {
    exoPlayer.playWhenReady = autoPlay
  }

  fun build(source: ReadableMap?) {
    val url = source?.getString("url") as String
    val startTime = source.getDouble("startTime")
    val thumbnailProps = source.getMap("thumbnails")

    if (url.isEmpty()) {
      return
    }

    val mediaItem = MediaItem.fromUri(Uri.parse(url))
    exoPlayer.setMediaItem(mediaItem, startTime.toLong())

    view.player = exoPlayer
    view.useController = false
    exoPlayer.prepare()

    val thumbnailUrl = thumbnailProps?.getString("url") as String
    val enabled = thumbnailProps.getBoolean("enableGenerate")

    if (enabled) {
      if (thumbnailUrl.isNotEmpty()) {
        this.thumbnailUrl = thumbnailUrl
      }
    }
  }

  fun getVideoPlayerView(): PlayerView {
    return view.findViewById(R.id.player)
  }

  @OptIn(UnstableApi::class)
  fun changeVideoQuality(newQualityUrl: String) {
    val currentMediaItem = exoPlayer.currentMediaItem
    val currentPosition = exoPlayer.currentPosition

    if (currentMediaItem?.localConfiguration?.uri.toString() == newQualityUrl) {
      return
    }

    val dataSourceFactory = DefaultDataSource.Factory(context)
    val newMediaItem = MediaItem.fromUri(newQualityUrl)
    val newMediaSource = DefaultMediaSourceFactory(dataSourceFactory).createMediaSource(newMediaItem)

    exoPlayer.setMediaSource(newMediaSource, currentPosition)
    exoPlayer.prepare()
  }

  fun seekToNextPosition(position: Long) {
    println("seekToNextPosition $position")
    exoPlayer.seekTo(exoPlayer.contentPosition + position)
  }

  fun seekToPreviousPosition(position: Long) {
    exoPlayer.seekTo(exoPlayer.contentPosition - position)
  }

  fun changeRate(rate: Float) {
    exoPlayer.setPlaybackSpeed(rate)
  }

  fun playerInitialized(callback: (Boolean) -> Unit) {
    exoPlayer.addListener(object : Player.Listener {
      override fun onPlaybackStateChanged(playbackState: Int) {
        super.onPlaybackStateChanged(playbackState)
        if (playbackState == Player.STATE_READY) {
            callback(true)
        }
      }
    })

  }
}
