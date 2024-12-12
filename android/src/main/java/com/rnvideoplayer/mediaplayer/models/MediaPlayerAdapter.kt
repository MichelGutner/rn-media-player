package com.rnvideoplayer.mediaplayer.models

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.SurfaceHolder
import android.view.SurfaceView
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.Util
import androidx.media3.exoplayer.ExoPlayer
import java.io.File

open class MediaPlayerAdapter(context: Context) {
  private val exoPlayer: ExoPlayer = ExoPlayer.Builder(context).build()
  val surfaceView: SurfaceView = SurfaceView(context)
  private val progressInterval: Long = 1000L
  private val handler = Handler(Looper.getMainLooper())
  val duration: Long get() = exoPlayer.duration

  interface Callback {
    fun onMediaLoaded(duration: Long)
    fun onPlaybackStateChanged(isPlaying: Boolean)
    var shouldShowPlayPause: Boolean
    fun onMediaError(error: PlaybackException?, mediaItem: MediaItem?)
    fun onMediaBuffering(currentProgress: Long, bufferedProgress: Long)
    fun getMediaMetadata(mediaMetadata: MediaMetadata)
  }

  init {
    setVideoSurface()
    shouldShowPlayPauseButton()
    exoPlayer.addListener(object : Player.Listener {
      override fun onEvents(player: Player, events: Player.Events) {
        super.onEvents(player, events)
        if (events.containsAny(
            Player.EVENT_PLAY_WHEN_READY_CHANGED,
            Player.EVENT_PLAYBACK_STATE_CHANGED,
            Player.EVENT_PLAYBACK_SUPPRESSION_REASON_CHANGED
          )
        ) {
          onPlaybackStateChanged(player.isPlaying)
        }
        if (events.contains(Player.EVENT_RENDERED_FIRST_FRAME)) {
          onMediaLoaded(player.duration)
        }
        if (events.contains(Player.EVENT_PLAYER_ERROR)) {
          onMediaError(player.playerError, player.currentMediaItem)
        }
        if (events.contains(Player.EVENT_IS_LOADING_CHANGED)) {
          startMediaProgress()
        }
      }
    })
  }

  private var callback: Callback? = null

  val shouldShowThumbnail: Boolean = false

  fun addCallback(callback: Callback) {
    this.callback = callback
  }

  private fun removeCallback() {
    this.callback = null
  }

  protected fun onPlaybackStateChanged(isPlaying: Boolean) {
    callback?.onPlaybackStateChanged(isPlaying)
  }

  protected fun onMediaLoaded(duration: Long) {
    callback?.onMediaLoaded(duration)
  }

  protected fun onMediaError(e: PlaybackException?, mediaItem: MediaItem?) {
    callback?.onMediaError(e, mediaItem)
  }

  protected fun onMediaBuffering(currentProgress: Long, bufferedProgress: Long) {
    callback?.onMediaBuffering(currentProgress, bufferedProgress)
  }

  protected fun getMediaItemMetadata(metadata: MediaMetadata) {
    callback?.getMediaMetadata(metadata)
  }

  private fun shouldShowPlayPauseButton() {
    callback?.shouldShowPlayPause = Util.shouldShowPlayButton(exoPlayer)
  }

  private fun initializeMediaPlayer(url: String, startTime: Long = 0, metadata: MediaMetadata?) {
    require(url.isNotEmpty()) { "URL cannot be empty." }

    val mediaItem = if (url.startsWith("file://")) {
      val localPath = url.removePrefix("file://")
      val file = File(localPath)

      require(file.exists() && file.canRead()) { "File does not exist or cannot be read: $localPath" }

      MediaItem.fromUri(Uri.fromFile(file))
    } else {
      MediaItem.fromUri(Uri.parse(url))
    }

    val mediaItemWithMetadata = if (metadata != null) { mediaItem.buildUpon().setMediaMetadata(metadata).build() } else { mediaItem }

    getMediaItemMetadata(mediaItemWithMetadata.mediaMetadata)
    exoPlayer.setMediaItem(mediaItemWithMetadata, startTime)
    exoPlayer.prepare()
  }

  private fun setVideoSurface() {
    val surfaceHolder = surfaceView.holder
    surfaceHolder?.addCallback(object : SurfaceHolder.Callback {
      override fun surfaceCreated(holder: SurfaceHolder) {
        exoPlayer.setVideoSurface(holder.surface)
      }

      override fun surfaceChanged(
        holder: SurfaceHolder,
        format: Int,
        width: Int,
        height: Int
      ) {
      }

      override fun surfaceDestroyed(holder: SurfaceHolder) {
        exoPlayer.setVideoSurface(null)
      }
    })
  }

  fun onBuild(url: String, startTime: Long? = 0, metadata: MediaMetadata?) {
    initializeMediaPlayer(url, startTime!!, metadata!!)
  }

  fun onAutoPlay(autoPlay: Boolean) {
    exoPlayer.playWhenReady = autoPlay
  }

  fun togglePlayPause() {
    if (exoPlayer.isPlaying) {
      exoPlayer.pause()
    } else {
      exoPlayer.play()
    }
  }

  fun release() {
    stopMediaProgress()
    removeCallback()
    exoPlayer.release()
  }

  fun seekTo(position: Long) {
    exoPlayer.seekTo(position)
  }

  private val progressTask = object : Runnable {
    override fun run() {
      if (exoPlayer.isPlaying) {
        val position = exoPlayer.contentPosition
        val buffered = exoPlayer.contentBufferedPosition
        onMediaBuffering(position, buffered)
      }
      handler.postDelayed(this, progressInterval)
    }
  }

  private fun startMediaProgress() {
    handler.post(progressTask)
  }

  private fun stopMediaProgress() {
    handler.removeCallbacksAndMessages(null)
  }
}
