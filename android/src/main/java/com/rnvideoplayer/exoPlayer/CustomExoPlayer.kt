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
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R

@UnstableApi
class CustomExoPlayer(private val context: ThemedReactContext, private val view: PlayerView) {
  private val exoPlayer: ExoPlayer = ExoPlayer.Builder(context).build();

  init {
    val inflater = LayoutInflater.from(context)
    inflater.inflate(R.layout.custom_player, view, true)
  }

  fun init() {
    view.player = exoPlayer
    view.useController = false
    exoPlayer.prepare()
    exoPlayer.playWhenReady = true
  }

  fun buildMediaItem(url: String, startTime: Long?) {
    val mediaItem = MediaItem.fromUri(Uri.parse(url))
    if (startTime != null) {
      exoPlayer.setMediaItem(mediaItem, startTime * 1000)
    } else {
      exoPlayer.setMediaItem(mediaItem)
    }
  }

  fun getExoPlayer(): ExoPlayer {
    return exoPlayer
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
