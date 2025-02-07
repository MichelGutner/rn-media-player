package com.rnvideoplayer.mediaplayer.views

import android.annotation.SuppressLint
import android.content.pm.ActivityInfo
import android.content.res.Configuration
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
import com.rnvideoplayer.mediaplayer.models.MediaPlayerSourceListener
import com.rnvideoplayer.mediaplayer.models.PlaybackState
import com.rnvideoplayer.mediaplayer.models.RCTConfigs
import com.rnvideoplayer.mediaplayer.viewModels.ControlType
import com.rnvideoplayer.mediaplayer.viewModels.EMediaPlayerFullscreen
import com.rnvideoplayer.mediaplayer.viewModels.EView
import com.rnvideoplayer.mediaplayer.viewModels.MediaPlayerContentScreen
import com.rnvideoplayer.mediaplayer.viewModels.MediaPlayerControls
import com.rnvideoplayer.mediaplayer.viewModels.MediaPlayerControlsViewListener
import com.rnvideoplayer.mediaplayer.viewModels.MediaPlayerScreenListener
import com.rnvideoplayer.mediaplayer.viewModels.components.options.CustomDialog
import com.rnvideoplayer.mediaplayer.viewModels.components.options.MediaPlayerMenuOptions
import com.rnvideoplayer.mediaplayer.viewModels.components.options.MediaPlayerMenuOptionsListener
import com.rnvideoplayer.mediaplayer.viewModels.components.options.OptionsDialogType
import com.rnvideoplayer.utils.TaskScheduler
import com.rnvideoplayer.utils.TimeUnitFormat
import java.util.concurrent.TimeUnit

@UnstableApi
@SuppressLint("ViewConstructor")
class MediaPlayerView(private val context: ThemedReactContext) : MediaPlayerContentScreen(context) {
  private val eventDispatcher = RCTDirectEvents(context, this)
  private var isSeeking = false

  private var taskManager = TaskScheduler()
  private var rctConfigs = RCTConfigs.getInstance()
  private var timeFormatter = TimeUnitFormat()
  private val mediaSource = MediaPlayerSource(context).apply { setListener(SourceListener()) }
  private val mediaControls = MediaPlayerControls(context).apply { setListener(ControlsViewListener()) }
  private val dialog by lazy { CustomDialog(context) }

  private var isFullscreen = false
  private var isFinished = false
  private var enterFullScreenWhenPlaybackBegins = false

  private val mediaPlayerSurfaceView = mediaSource.surfaceView
  private var currentProgress: Long = 0
  private var currentItem: MediaItem? = null

  init {
    registerView(mediaControls)

    setupReactConfigs()
    mediaControls.seekBarListener(
      mediaSource,
      getIsSeeking = {
        isSeeking = it
      }
    ) { isLastPosition, scrubberPosition ->
      eventDispatcher.onMediaSeekBar(
        scrubberPosition.startPositionSeconds.toDouble(),
        scrubberPosition.startPositionPercent.toDouble(),
        scrubberPosition.endPositionSeconds.toDouble(),
        scrubberPosition.endPositionPercent.toDouble(),
      )
      isFinished = isLastPosition
      scheduleTimeoutControls()
    }

    setListener(ContentScreenListener())
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    mediaControls.setSurfaceMediaPlayerView(mediaPlayerSurfaceView)

    val enterFullscreenWhenPlaybackBeginsConfig =
      rctConfigs.get(RCTConfigs.Key.ENTERS_FULL_SCREEN_WHEN_PLAYBACK_BEGINS)
        ?: false
    enterFullScreenWhenPlaybackBegins = enterFullscreenWhenPlaybackBeginsConfig as Boolean

    postDelayed({
      scheduleTimeoutControls()
      if (enterFullscreenWhenPlaybackBeginsConfig) {
        enterFullscreen()
      }
    }, 400)
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    mediaPlayerRelease()
    context.currentActivity?.apply {
      requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
    }
    exitFullscreen()
  }

  @SuppressLint("SwitchIntDef")
  override fun onConfigurationChanged(newConfig: Configuration?) {
    super.onConfigurationChanged(newConfig)
//    when(newConfig?.orientation) {
//      Configuration.ORIENTATION_LANDSCAPE -> {
//       onChangeFullscreenState(true)
//      }
//      Configuration.ORIENTATION_PORTRAIT -> {
//        onChangeFullscreenState(false)
//      }
//    }
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
          gestureSeekSuffix =
            rctConfigs.get(RCTConfigs.Key.DOUBLE_TAP_TO_SEEK_SUFFIX_LABEL).toString()
        }

        mediaControls.modifyConfigLeftGestureSeek(gestureSeekValue, gestureSeekSuffix)
        mediaControls.modifyConfigRightGestureSeek(gestureSeekValue, gestureSeekSuffix)

        viewTreeObserver.removeOnGlobalLayoutListener(this)
      }
    })
  }

  private fun toggleFullscreen() {
    if (mediaSource.isPlaying) {
      mediaControls.hideOverlay(animated = false)
    }
    scheduleTimeoutControls()
    if (isFullscreen) {
      exitFullscreen()
    } else {
      enterFullscreen()
    }
  }

  private fun scheduleTimeoutControls() {
    taskManager.cancelTask()

    taskManager.createTask(3500) {
      if (mediaSource.isPlaying && !isSeeking) {
        mediaControls.hideOverlay()
      }
    }
  }

  private fun mediaPlayerRelease() {
    mediaSource.onMediaRelease()
    taskManager.cancelTask()
  }

  fun setupMediaPlayer(url: String, startTime: Long? = 0, metadata: MediaMetadata? = null) {
    mediaSource.onMediaBuild(url, startTime, metadata)
  }

  fun onAutoPlay(autoPlayer: Boolean) {
    mediaSource.onMediaAutoPlay(autoPlayer)
  }

  fun onChangePlaybackSpeed(rate: Float) {
//    mediaSource.onMediaChangePlaybackSpeed(rate)
  }

  fun onReplaceMedia(url: String) {
    val currentMetadata = currentItem?.mediaMetadata
    if (currentItem?.localConfiguration?.uri.toString() == url) return
    mediaSource.onMediaBuild(url, currentProgress, currentMetadata)
  }

  fun downloadThumbnailFrames(url: String) {
    mediaControls.shouldExecuteDownloadThumbnailFrames(url)
  }

  private inner class SourceListener : MediaPlayerSourceListener {
    override fun onPlaybackInstance(player: ExoPlayer) {
      currentItem = player.currentMediaItem
      mediaControls.setVideoTitle(player.mediaMetadata.title.toString())
    }

    override fun onPlaybackStateChange(playbackStateChanged: PlaybackState) {
      Debug.log(playbackStateChanged.toString())
      when (playbackStateChanged) {
        PlaybackState.PLAYING -> {
          mediaControls.updateAnimatedPlayPauseIcon(true)
        }

        PlaybackState.PAUSED -> {
          mediaControls.updateAnimatedPlayPauseIcon(false)
        }

        PlaybackState.ENDED -> {
          eventDispatcher.onMediaCompleted()
          mediaControls.updateAnimatedPlayPauseIcon(false)
        }

        PlaybackState.NONE -> {
          mediaControls.updateAnimatedPlayPauseIcon(false)
        }

        PlaybackState.WAITING -> {}
      }
    }

    override fun onPlaybackStart(started: Boolean, duration: Long) {
      mediaControls.setSeekBarDuration(duration)
      eventDispatcher.onMediaReady(timeFormatter.toSecondsDouble(duration))
      mediaControls.removeLoading()
    }

    override fun onPlaybackChangeBuffering(currentProgress: Long, bufferedProgress: Long) {
      this@MediaPlayerView.currentProgress = currentProgress
      mediaControls.setSeekBarProgress(currentProgress, bufferedProgress)
      eventDispatcher.onMediaBuffering(
        TimeUnit.MILLISECONDS.toSeconds(currentProgress).toDouble(),
        TimeUnit.MILLISECONDS.toSeconds(bufferedProgress).toDouble()
      )
    }

    override fun onPlaybackBufferCompleted(bufferCompleted: Boolean) {
      eventDispatcher.onMediaBufferCompleted()
    }

    override fun onPLayBackError(error: PlaybackException, currentItem: MediaItem?) {
      val uri = currentItem?.localConfiguration?.uri
      eventDispatcher.onMediaError(
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

  private inner class ControlsViewListener : MediaPlayerControlsViewListener {
    override fun control(type: ControlType, event: Any?) {
      when (type) {
        ControlType.PLAY_PAUSE -> {
          mediaSource.onMediaTogglePlaybackState { oldState: PlaybackState ->
            if (oldState == PlaybackState.ENDED) {
              mediaControls.setThumbnailPositionX(0f)
            }
          }
          scheduleTimeoutControls()
        }

        ControlType.FULLSCREEN -> toggleFullscreen()
        ControlType.OPTIONS_MENU -> {
            val content by lazy { MediaPlayerMenuOptions(context, dialog).apply { setListener(MenuOptionsListener()) } }
            val reactConfigAdapter = RCTConfigs.getInstance()
            val menuItems = (reactConfigAdapter.get(RCTConfigs.Key.MENU_ITEMS) as? Set<*>)?.filterIsInstance<String>()
            content.showOptionsDialog(menuItems!!)
        }

        ControlType.SEEK_GESTURE_FORWARD -> {
          mediaSource.seekToRelativePosition((event as Int * 1000).toLong())
        }

        ControlType.SEEK_GESTURE_BACKWARD -> {
          mediaSource.seekToRelativePosition(-(event as Int * 1000).toLong())
        }

        ControlType.PINCH_ZOOM -> eventDispatcher.onMediaPinchZoom(event.toString())
        ControlType.TOUCH_VIEW -> scheduleTimeoutControls()
      }
    }
  }

  private inner class ContentScreenListener : MediaPlayerScreenListener {
    override fun onScreenStateChanged(currentState: EMediaPlayerFullscreen) {
      when (currentState) {
        EMediaPlayerFullscreen.NOT_FULLSCREEN -> {
          eventDispatcher.onFullScreenStateChanged(false) // TODO: need implement enum
          isFullscreen = false
          mediaControls.updateFullscreenIcon(false)
          mediaControls.setOverlayPadding(14f)
        }

        EMediaPlayerFullscreen.IN_TRANSITION -> {
          Debug.log("in transition to fullscreen or not")
          isFullscreen = false
        }

        EMediaPlayerFullscreen.FULLSCREEN -> {
          isFullscreen = true
          eventDispatcher.onFullScreenStateChanged(true)
          mediaControls.updateFullscreenIcon(true)
          mediaControls.setOverlayPadding(24f)
        }
      }
    }

    override fun onView(state: EView, viewId: Int) {
      when (state) {
        EView.REGISTERED -> {
          Debug.log("Registered view with id: $viewId")

        }

        EView.UNREGISTERED -> {
          Debug.log("Unregistered view with id: $viewId")
        }
      }
    }
  }

  private inner class MenuOptionsListener : MediaPlayerMenuOptionsListener {
    override fun onSelected(optionType: OptionsDialogType, title: String, value: Any) {
      when (optionType) {
        OptionsDialogType.SPEEDS -> {
          mediaSource.onMediaChangePlaybackSpeed(value as Double)
        }

        OptionsDialogType.QUALITIES -> {
          onReplaceMedia(value as String)
        }

        OptionsDialogType.CAPTIONS -> {
//          mediaSource.onMediaChangeCaption(value as String)
        }
      }

      eventDispatcher.onMenuItemSelected(title, value)
    }

  }
}

