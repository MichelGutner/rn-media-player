package com.rnvideoplayer.mediaplayer.views

import android.annotation.SuppressLint
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.mediaplayer.logger.Debug
import com.rnvideoplayer.mediaplayer.models.RCTDirectEvents
import com.rnvideoplayer.mediaplayer.models.MediaPlayerSource
import com.rnvideoplayer.mediaplayer.models.IMediaPlayerSourceListener
import com.rnvideoplayer.mediaplayer.models.PlaybackState
import com.rnvideoplayer.mediaplayer.models.RCTConfigs
import com.rnvideoplayer.mediaplayer.viewModels.ControlType
import com.rnvideoplayer.mediaplayer.viewModels.MediaPlayerControls
import com.rnvideoplayer.mediaplayer.viewModels.MediaPlayerControlsViewListener
import com.rnvideoplayer.mediaplayer.viewModels.components.PopUpMenu
import com.rnvideoplayer.utils.TaskScheduler
import com.rnvideoplayer.utils.TimeUnitFormat
import java.util.concurrent.TimeUnit


@SuppressLint("ViewConstructor")
@UnstableApi
class MediaPlayerView(private val context: ThemedReactContext) : MediaPlayerControls(context) {
  private val rctEvent = RCTDirectEvents(context, this)
  private var fullscreenDialog = FullscreenDialog(context)
  private var isSeeking = false

  private var taskScheduler = TaskScheduler()
  private var rctConfigs = RCTConfigs.getInstance()
  private var timeUnitHandler = TimeUnitFormat()
  private val mediaPlayer = MediaPlayerSource(context)


  private var isFullscreen = false
  private var isFinished = false
  private var enterFullScreenWhenPlaybackBegins = false

  private val mediaPlayerSurfaceView = mediaPlayer.surfaceView
  private var currentProgress: Long = 0
  private var currentItem: MediaItem? = null

  init {
    setupReactConfigs()
    seekBarListener(
      mediaPlayer,
      getIsSeeking = {
        isSeeking = it
      }
    ) { isLastPosition, scrubberPosition ->
      rctEvent.onMediaSeekBar(
        scrubberPosition.startPositionSeconds.toDouble(),
        scrubberPosition.startPositionPercent.toDouble(),
        scrubberPosition.endPositionSeconds.toDouble(),
        scrubberPosition.endPositionPercent.toDouble(),
      )
      isFinished = isLastPosition
      scheduleTimeoutControls()
    }
    mediaPlayer.setListener(MediaPlayerSourceListener())
    this.setListener(MediaPlayerControlsListener())
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    setSurfaceMediaPlayerView(mediaPlayerSurfaceView)

    val enterFullscreenWhenPlaybackBeginsConfig =
      rctConfigs.get(RCTConfigs.Key.ENTERS_FULL_SCREEN_WHEN_PLAYBACK_BEGINS)
        ?: false
    enterFullScreenWhenPlaybackBegins = enterFullscreenWhenPlaybackBeginsConfig as Boolean

    postDelayed({
      scheduleTimeoutControls()
      if (enterFullscreenWhenPlaybackBeginsConfig) {
        mutateFullScreenState(enterFullScreenWhenPlaybackBegins)
      }
    }, 400)
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    mediaPlayerRelease()
    context.currentActivity?.apply {
      requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
    }
  }

  override fun onConfigurationChanged(newConfig: Configuration?) {
    super.onConfigurationChanged(newConfig)
    if (newConfig?.orientation == Configuration.ORIENTATION_PORTRAIT && isFullscreen) {
      context.currentActivity?.requestedOrientation =
        ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
    }
  }

  @SuppressLint("ClickableViewAccessibility", "SourceLockedOrientationActivity")
  fun onFullscreenMode(isFullscreen: Boolean) {
    val parent = mainLayout.parent as? ViewGroup
    parent?.removeView(mainLayout)

    if (isFullscreen) {
      fullscreenDialog = FullscreenDialog(context).apply {
        setOnDismissListener {
          onFullscreenMode(false)
        }
        mainLayout.setOnTouchListener { _, event ->
          this@MediaPlayerView.onTouchEvent(event)
          true
        }
        setContentView(mainLayout)
        show()
      }

      context.currentActivity?.apply {
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
      }
    } else {
      fullscreenDialog.dismiss()
      addView(mainLayout)

      context.currentActivity?.apply {
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
      }

      postDelayed({
        context.currentActivity?.apply {
          requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        }
      }, 1500)
    }
  }

  private fun setupReactConfigs() {
    viewTreeObserver.addOnGlobalLayoutListener(object :
      ViewTreeObserver.OnGlobalLayoutListener {
      override fun onGlobalLayout() {
        var gestureSeekValue = 10
        var gestureSeekSuffix = "seconds"
        if (rctConfigs.get(RCTConfigs.Key.DOUBLE_TAP_TO_SEEK_VALUE) != null) {
          gestureSeekValue = rctConfigs.get(RCTConfigs.Key.DOUBLE_TAP_TO_SEEK_VALUE) as Int
        }

        if (rctConfigs.get(RCTConfigs.Key.DOUBLE_TAP_TO_SEEK_SUFFIX_LABEL) != null) {
          gestureSeekSuffix = rctConfigs.get(RCTConfigs.Key.DOUBLE_TAP_TO_SEEK_SUFFIX_LABEL).toString()
        }

        modifyConfigLeftGestureSeek(gestureSeekValue, gestureSeekSuffix)
        modifyConfigRightGestureSeek(gestureSeekValue, gestureSeekSuffix)

        viewTreeObserver.removeOnGlobalLayoutListener(this)
      }
    })
  }

  private fun toggleFullscreen() {
    hideOverlay(animated = false)
    scheduleTimeoutControls()
    mutateFullScreenState(!isFullscreen)
    rctEvent.onFullScreenStateChanged(isFullscreen)
  }

  private fun mutateFullScreenState(state: Boolean) {
    onFullscreenMode(state)
    updateFullscreenIcon(state)
    isFullscreen = state
  }

  private fun showPopUp(view: View) {
    val popupMenu by lazy {
      PopUpMenu(context, view) { title, value ->
        rctEvent.onMenuItemSelected(title, value)
      }
    }
    popupMenu.show()
  }

  private fun scheduleTimeoutControls() {
    taskScheduler.cancelTask()

    taskScheduler.createTask(3500) {
      if (mediaPlayer.isPlaying && !isSeeking) {
        hideOverlay()
      }
    }
  }

  private fun mediaPlayerRelease() {
    mediaPlayer.onMediaRelease()
    taskScheduler.cancelTask()
  }

  fun setupMediaPlayer(url: String, startTime: Long? = 0, metadata: MediaMetadata? = null) {
    mediaPlayer.onMediaBuild(url, startTime, metadata)
  }

  fun onAutoPlay(autoPlayer: Boolean) {
    mediaPlayer.onMediaAutoPlay(autoPlayer)
  }

  fun onChangePlaybackSpeed(rate: Float) {
    mediaPlayer.onMediaChangePlaybackSpeed(rate)
  }

  fun onReplaceMedia(url: String) {
    val currentMetadata = currentItem?.mediaMetadata
    if (currentItem?.localConfiguration?.uri.toString() == url) return

    /*      val dataSourceFactory = DefaultDataSource.Factory(context)
          val newMediaItem = MediaItem.fromUri(url)
          val newMediaSource =
            DefaultMediaSourceFactory(dataSourceFactory).createMediaSource(newMediaItem)

          mediaPlayer.setMediaSource(newMediaSource, currentPosition)
          mediaPlayer.prepare()*/
    mediaPlayer.onMediaBuild(url, currentProgress, currentMetadata)
  }

  private inner class MediaPlayerSourceListener : IMediaPlayerSourceListener {
    override fun onPlaybackInstance(player: ExoPlayer) {
      currentItem = player.currentMediaItem
      setVideoTitle(player.mediaMetadata.title.toString())
    }

    override fun onPlaybackStateChange(playbackStateChanged: PlaybackState) {
      Debug.log(playbackStateChanged.toString())
      when(playbackStateChanged) {
        PlaybackState.PLAYING -> {
          updateAnimatedPlayPauseIcon(true)
        }
        PlaybackState.PAUSED -> {
          updateAnimatedPlayPauseIcon(false)
        }
        PlaybackState.ENDED -> {
          rctEvent.onMediaCompleted()
          updateAnimatedPlayPauseIcon(false)
        }
        PlaybackState.NONE -> {
          updateAnimatedPlayPauseIcon(false)
        }
        PlaybackState.WAITING -> {}
      }
    }

    override fun onPlaybackStart(started: Boolean, duration: Long) {
      setSeekBarDuration(duration)
      rctEvent.onMediaReady(timeUnitHandler.toSecondsDouble(duration))
      removeLoading()
    }

    override fun onPlaybackChangeBuffering(currentProgress: Long, bufferedProgress: Long) {
      this@MediaPlayerView.currentProgress = currentProgress
      setSeekBarProgress(currentProgress, bufferedProgress)
      rctEvent.onMediaBuffering(
        TimeUnit.MILLISECONDS.toSeconds(currentProgress).toDouble(),
        TimeUnit.MILLISECONDS.toSeconds(bufferedProgress).toDouble()
      )
    }

    override fun onPlaybackBufferCompleted(bufferCompleted: Boolean) {
      rctEvent.onMediaBufferCompleted()
    }

    override fun onPLayBackError(error: PlaybackException, currentItem: MediaItem?) {
      val uri = currentItem?.localConfiguration?.uri
      rctEvent.onMediaError(
        uri.toString(),
        error,
        mapOf(
          "NSLocalizedDescriptionKey" to error.message,
          "NSLocalizedFailureReasonErrorKey" to "Failed to play the video.",
          "NSLocalizedRecoverySuggestionErrorKey" to "Please check the video source or try again later."
        ).toString()
      )
    }
  }

  private inner class MediaPlayerControlsListener : MediaPlayerControlsViewListener {
    override fun control(type: ControlType, event: Any?) {
      when(type) {
        ControlType.PLAY_PAUSE -> {
          mediaPlayer.onMediaTogglePlaybackState { oldState: PlaybackState ->
            if (oldState == PlaybackState.ENDED) {
              setThumbnailPositionX(0f)
            }
          }
          scheduleTimeoutControls()
        }
        ControlType.FULLSCREEN -> toggleFullscreen()
        ControlType.OPTIONS_MENU -> showPopUp(event as View)
        ControlType.SEEK_GESTURE_FORWARD -> {
          mediaPlayer.seekToRelativePosition(-((event as Int * 1000).toLong()))
        }
        ControlType.SEEK_GESTURE_BACKWARD -> {
          mediaPlayer.seekToRelativePosition((event as Int * 1000).toLong())
        }

        ControlType.PINCH_ZOOM -> rctEvent.onMediaPinchZoom(event.toString())
        ControlType.TOUCH_VIEW -> scheduleTimeoutControls()
      }
    }
  }
}

