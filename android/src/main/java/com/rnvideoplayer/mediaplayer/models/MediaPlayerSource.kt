package com.rnvideoplayer.mediaplayer.models

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.SurfaceHolder
import android.view.SurfaceView
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.common.text.CueGroup
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.ui.CaptionStyleCompat
import androidx.media3.ui.SubtitleView
import com.rnvideoplayer.mediaplayer.logger.Debug
import com.rnvideoplayer.utils.TaskScheduler
import com.rnvideoplayer.utils.Utils
import java.io.File

enum class PlaybackState {
  PLAYING,
  PAUSED,
  ENDED,
  NONE,
  WAITING
}

interface MediaPlayerSourceListener {
  fun onPlaybackInitialized(player: ExoPlayer)
  fun onPlaybackStateChange(playbackStateChanged: PlaybackState)
  fun onPlaybackStart(started: Boolean, duration: Long)
  fun onPlaybackChangeBuffering(currentProgress: Long, bufferedProgress: Long)
  fun onPlaybackBufferCompleted(bufferCompleted: Boolean)
  fun onPLayBackError(error: PlaybackException, currentItem: MediaItem? = null)
}

@UnstableApi
abstract class MediaPlayer(context: Context) {
  val subtitleView = SubtitleView(context)
  val closedCaptions: MutableList<Format> = mutableListOf()
  val trackSelector = DefaultTrackSelector(context)
  private val trackInitDisabled =
    trackSelector.parameters.buildUpon().setRendererDisabled(C.TRACK_TYPE_TEXT, true)

  val exoPlayer: ExoPlayer = ExoPlayer.Builder(context)
    .setTrackSelector(trackSelector)
    .build()

  companion object {
    private const val TAG = "MediaPlayer"
  }

  init {
    trackSelector.parameters = trackInitDisabled.build()
    modifyStyleSubtitle()
    exoPlayer.addListener(object : Player.Listener {
      override fun onTracksChanged(tracks: Tracks) {
        if (closedCaptions.isEmpty()) {
          extractEmbeddedClosedCaptions()
        }
      }

      override fun onCues(cueGroup: CueGroup) {
        super.onCues(cueGroup)
        for (cue in cueGroup.cues) {
          if (!trackSelector.parameters.getRendererDisabled(C.TRACK_TYPE_TEXT)) {
            subtitleView.setCues(cueGroup.cues)
            TaskScheduler().cancelTask()
          } else {
            subtitleView.setCues(null)
          }

          TaskScheduler().createTask(3000) {
            subtitleView.setCues(null)
            TaskScheduler().cancelTask()
          }
        }
      }
    })
  }

  private fun extractEmbeddedClosedCaptions() {
    val mappedTrackInfo = trackSelector.currentMappedTrackInfo
    if (mappedTrackInfo == null) {
      Debug.log("$TAG: No track info available")
      return
    }

    for (i in 0 until mappedTrackInfo.rendererCount) {
      if (exoPlayer.getRendererType(i) == C.TRACK_TYPE_TEXT) {
        val groups = mappedTrackInfo.getTrackGroups(i)

        for (groupIndex in 0 until groups.length) {
          val trackGroup = groups[groupIndex]

          for (trackIndex in 0 until trackGroup.length) {
            val format = trackGroup.getFormat(trackIndex)
            closedCaptions.add(format)
          }
        }
      }
    }
  }

  private fun modifyStyleSubtitle() {
    subtitleView.setPadding(12,12,12,12)
    subtitleView.setStyle(
      CaptionStyleCompat(
        Color.WHITE,
        Utils.COLOR_BLACK_ALPHA_03,
        Color.TRANSPARENT,
        CaptionStyleCompat.EDGE_TYPE_OUTLINE,
        Color.TRANSPARENT,
        null
      )
    )
  }
}

@OptIn(UnstableApi::class)
open class MediaPlayerSource(context: Context) : MediaPlayer(context) {
  private val progressInterval: Long = 1000L
  private val handler = Handler(Looper.getMainLooper())
  private var callback: Callback? = null
  private var listener: MediaPlayerSourceListener? = null

  private var playbackState: PlaybackState = PlaybackState.NONE
  private var isInitialized: Boolean = false

  val surfaceView: SurfaceView = SurfaceView(context)
  val duration: Long get() = exoPlayer.duration
  val isPlaying: Boolean get() = exoPlayer.isPlaying

  interface Callback {
    fun onMediaEnded()
  }

  init {
    setVideoSurface()
    exoPlayer.addListener(object : Player.Listener {
      override fun onPlayerError(error: PlaybackException) {
        super.onPlayerError(error)
        listener?.onPLayBackError(error, exoPlayer.currentMediaItem)
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

      override fun onEvents(player: Player, events: Player.Events) {
        super.onEvents(player, events)
        if (!isInitialized) {
          isInitialized = true
          if (player.playWhenReady) {
            setPlaybackState(PlaybackState.PLAYING)
          } else {
            setPlaybackState(PlaybackState.PAUSED)
          }
        }

        if (player.isPlaying && playbackState == PlaybackState.ENDED) {
          setPlaybackState(PlaybackState.PLAYING)
        }
      }

      override fun onRenderedFirstFrame() {
        super.onRenderedFirstFrame()
        Log.d(TAG, "Media Player has been rendered first frame")
        startMediaProgress()
        listener?.onPlaybackStart(true, exoPlayer.duration)
      }
    })
  }

  fun setListener(listener: MediaPlayerSourceListener?) {
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

  private fun removeCallback() {
    this.callback = null
  }

  protected fun onMediaEnded() {
    callback?.onMediaEnded()
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

    exoPlayer.setMediaItem(mediaItemWithMetadata, startTime)
    exoPlayer.prepare()
    listener?.onPlaybackInitialized(exoPlayer)
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

        val position = exoPlayer.contentPosition
        val totalBuffered = exoPlayer.contentBufferedPosition
        val isBufferingCompleted = totalBuffered == duration
        listener?.onPlaybackChangeBuffering(position, totalBuffered)

        if (isBufferingCompleted) {
          listener?.onPlaybackBufferCompleted(true)
        }

      if (exoPlayer.isPlaying) {
        handler.postDelayed(this, progressInterval)
      }
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

  fun onMediaChangePlaybackSpeed(rate: Double) {
    exoPlayer.setPlaybackSpeed(rate.toFloat())
  }

  fun onMediaTogglePlaybackState(onStateChange: (oldState: PlaybackState) -> Unit = { _ -> }) {
    val currentState = playbackState

    when (currentState) {
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
    onStateChange(currentState)
  }

  fun onMediaSelectCaption(language: String?) {
    val parametersBuilder = trackSelector.parameters.buildUpon()

    Debug.log("$TAG: Language = ${language?.isEmpty()}")

    if (language.isNullOrEmpty()) {
      Debug.log("$TAG: Language is null")
      parametersBuilder.setRendererDisabled(C.TRACK_TYPE_TEXT, true)
    } else {
      parametersBuilder.setRendererDisabled(C.TRACK_TYPE_TEXT, false)
        .setPreferredTextLanguage(language) // Use setPreferredTextLanguage (sem "s")
    }

    trackSelector.parameters =
      parametersBuilder.build() // ⚠️ ESSENCIAL: Aplicar os novos parâmetros

    Debug.log(
      "Selected language: $language parameters = ${
        trackSelector.parameters.getRendererDisabled(
          C.TRACK_TYPE_TEXT
        )
      }"
    )
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
    private val TAG = MediaPlayerSource::class.java.simpleName
  }
}
