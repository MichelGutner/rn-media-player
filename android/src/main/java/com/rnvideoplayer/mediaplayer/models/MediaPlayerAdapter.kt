package com.rnvideoplayer.mediaplayer.models

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.SurfaceHolder
import android.view.SurfaceView
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import com.rnvideoplayer.mediaplayer.logger.Debug
import java.io.File

enum class PlaybackState {
  PLAYING,
  PAUSED,
  ENDED,
  NONE,
  WAITING
}

interface MediaPlayerListener {
  fun onPlaybackStateChange(playbackStateChanged: PlaybackState)
  fun onPlaybackStart(started: Boolean, duration: Long)
  fun onPlaybackChangeBuffering(currentProgress: Long, bufferedProgress: Long)
}

open class MediaPlayerAdapter(context: Context) {
  private val exoPlayer: ExoPlayer = ExoPlayer.Builder(context).build()
  private val progressInterval: Long = 1000L
  private val handler = Handler(Looper.getMainLooper())
  private var callback: Callback? = null
  private var listener: MediaPlayerListener? = null

  private var playbackState: PlaybackState = PlaybackState.NONE
  private var isInitialized: Boolean = false

  val surfaceView: SurfaceView = SurfaceView(context)
  val duration: Long get() = exoPlayer.duration
  val currentMediaItem: MediaItem? get() = exoPlayer.currentMediaItem
  val currentProgress: Long get() = exoPlayer.currentPosition
  val isPlaying: Boolean get() = exoPlayer.isPlaying
  val instance: ExoPlayer get() = exoPlayer

  interface Callback {
    fun onMediaLoaded(duration: Long)
    fun onPlaybackStateChanged(isPlaying: Boolean)
    fun onMediaError(error: PlaybackException?, mediaItem: MediaItem?)
    fun onMediaBuffering(currentProgress: Long, bufferedProgress: Long)
    fun onMediaBufferCompleted()
    fun getMediaMetadata(mediaMetadata: MediaMetadata)
    fun onPlaybackStateEndedInvoked()
    fun onMediaEnded()
  }

  init {
    setVideoSurface()
    exoPlayer.addListener(object : Player.Listener {
      @SuppressLint("WrongConstant")
      override fun onEvents(player: Player, events: Player.Events) {
        super.onEvents(player, events)
        if (!isInitialized && events.containsAny(
            Player.EVENT_PLAY_WHEN_READY_CHANGED,
            Player.EVENT_PLAYBACK_STATE_CHANGED,
            Player.EVENT_PLAYBACK_SUPPRESSION_REASON_CHANGED
          )
        ) {
          isInitialized = true
//          onPlaybackStateChanged(player.isPlaying)
          if (player.playWhenReady) {
            setPlaybackState(PlaybackState.PLAYING)
          } else {
            setPlaybackState(PlaybackState.PAUSED)
          }
          return
        }
        if (events.contains(Player.EVENT_RENDERED_FIRST_FRAME)) {
          Log.d(TAG, "Media Player has been rendered first frame")
          startMediaProgress()
          listener?.onPlaybackStart(true, instance.duration)
          return
        }
        if (events.contains(Player.EVENT_PLAYER_ERROR)) {
          onMediaError(player.playerError, player.currentMediaItem)
          return
        }
      }

      @SuppressLint("SwitchIntDef")
      override fun onPlaybackStateChanged(playbackState: Int) {
        super.onPlaybackStateChanged(playbackState)
        when (playbackState) {
          ExoPlayer.STATE_ENDED -> {
            setPlaybackState(PlaybackState.ENDED)
            onMediaEnded()
          }
        }
      }
    })
  }

  fun setListener(listener: MediaPlayerListener?) {
    this.listener = listener
  }

  protected fun setPlaybackState(state: PlaybackState) {
    playbackState = when (state) {
      PlaybackState.PLAYING -> {
        PlaybackState.PLAYING
      }
      PlaybackState.PAUSED -> {
        PlaybackState.PAUSED
      }
      PlaybackState.WAITING -> {
        PlaybackState.WAITING
      }
      PlaybackState.ENDED -> {
        PlaybackState.ENDED
      }
      PlaybackState.NONE -> {
        PlaybackState.NONE
      }
    }
    listener?.onPlaybackStateChange(playbackState)
  }

  fun addCallback(callback: Callback) {
    this.callback = callback
  }

  private fun removeCallback() {
    this.callback = null
  }

  protected fun onMediaEnded() {
    callback?.onMediaEnded()
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

  protected fun onMediaBufferCompleted() {
    callback?.onMediaBufferCompleted()
  }

  private fun getMediaItemMetadata(metadata: MediaMetadata) {
    callback?.getMediaMetadata(metadata)
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

    val mediaItemWithMetadata = if (metadata != null) {
      mediaItem.buildUpon().setMediaMetadata(metadata).build()
    } else {
      mediaItem
    }

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

  private val progressTask = object : Runnable {
    override fun run() {
      if (exoPlayer.isPlaying) {
        val position = exoPlayer.contentPosition
        val buffered = exoPlayer.contentBufferedPosition
        onMediaBuffering(position, buffered)

        if (buffered == duration) {
          onMediaBufferCompleted()
        }
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

  private fun onPause() {
    exoPlayer.pause()
    setPlaybackState(PlaybackState.PAUSED)
  }

  private fun onPlay() {
    exoPlayer.play()
    setPlaybackState(PlaybackState.PLAYING)
  }

  private fun onReplay() {
    exoPlayer.seekTo(0)
    exoPlayer.play()
    setPlaybackState(PlaybackState.PLAYING)
  }

  fun onMediaBuild(url: String, startTime: Long? = 0, metadata: MediaMetadata?) {
    initializeMediaPlayer(url, startTime!!, metadata!!)
  }

  fun onMediaAutoPlay(autoPlay: Boolean) {
    exoPlayer.playWhenReady = autoPlay
  }

  fun onMediaChangePlaybackSpeed(rate: Float) {
    exoPlayer.setPlaybackSpeed(rate)
  }

  // TODO: need refactor
  fun onMediaTogglePlayPause() {
    when (playbackState) {
      PlaybackState.PLAYING -> {
        this.onPause()
      }

      PlaybackState.PAUSED -> {
        this.onPlay()
      }
      PlaybackState.ENDED -> {
        this.onReplay()
      }
      PlaybackState.NONE -> {
        this.onPlay()
      }
      PlaybackState.WAITING -> {}
    }
  }

  fun onMediaRelease() {
    Debug.log("[$TAG] Media player instance has been released. All associated resources have been cleaned up.")
    stopMediaProgress()
    removeCallback()
    exoPlayer.release()
    this.setListener(null)
  }

  fun seekTo(position: Long) {
    val duration = exoPlayer.duration
    val newPosition = (position).coerceIn(0, duration)

    exoPlayer.seekTo(newPosition)
  }

  fun seekToRelativePosition(position: Long) {
    val currentPosition = exoPlayer.currentPosition
    val duration = exoPlayer.duration
    val newPosition = (currentPosition + position).coerceIn(0, duration)
    exoPlayer.seekTo(newPosition)
  }

  companion object {
    private val TAG = MediaPlayerAdapter::class.java.simpleName
  }
}
