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
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.mediaplayer.models.RCTDirectEvents
import com.rnvideoplayer.mediaplayer.models.MediaPlayerAdapter
import com.rnvideoplayer.mediaplayer.models.RCTConfigs
import com.rnvideoplayer.mediaplayer.viewModels.MediaPlayerControls
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
  private val mediaPlayer = MediaPlayerAdapter(context)


  private var isFullscreen = false
  private var isFinished = false
  private var enterFullScreenWhenPlaybackBegins = false

  private val mediaPlayerSurfaceView = mediaPlayer.surfaceView

  init {
    setupReactConfigs()
    setupPlayerCallbacks()
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
      timeoutControls()
    }
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    setSurfaceMediaPlayerView(mediaPlayerSurfaceView)

    addMediaPlayerControlsCallback(object : Callback {
      override fun setOnPlayPauseClickListener() {
        mediaPlayer.onMediaTogglePlayPause()
        timeoutControls()
      }

      override fun setOnFullscreenClickListener() {
        toggleFullscreen()
      }

      override fun setOnOptionsMenuButtonClickListener(anchorView: View) {
        showPopUp(anchorView)
      }

      override fun setOnLeftSeekGestureClickListener(receivedValue: Int) {
        mediaPlayer.seekToRelativePosition(-((receivedValue * 1000).toLong()))
      }

      override fun setOnRightSeekGestureClickListener(receivedValue: Int) {
        mediaPlayer.seekToRelativePosition(((receivedValue * 1000).toLong()))
      }

      override fun onPinchZoomChanged(zoom: String) {
        rctEvent.onMediaPinchZoom(zoom)
      }

      override fun onViewSingleTouchFinished() {
        timeoutControls()
      }
    })

    val enterFullscreenWhenPlaybackBeginsConfig =
      rctConfigs.get(RCTConfigs.Key.ENTERS_FULL_SCREEN_WHEN_PLAYBACK_BEGINS)
        ?: false
    enterFullScreenWhenPlaybackBegins = enterFullscreenWhenPlaybackBeginsConfig as Boolean

    postDelayed({
      timeoutControls()
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

  private fun setupPlayerCallbacks() {
    mediaPlayer.addCallback(object : MediaPlayerAdapter.Callback {
      override fun onMediaLoaded(duration: Long) {
        setSeekBarDuration(duration)
        rctEvent.onMediaReady(timeUnitHandler.toSecondsDouble(duration))
        removeLoading()
      }

      override fun onPlaybackStateChanged(isPlaying: Boolean) {
        updateAnimatedPlayPauseIcon(isPlaying)
        rctEvent.onMediaPlayPause(isPlaying)
      }

      override fun onMediaError(error: PlaybackException?, mediaItem: MediaItem?) {
        val uri = mediaItem?.localConfiguration?.uri
        rctEvent.onMediaError(
          uri.toString(),
          error,
          mapOf(
            "NSLocalizedDescriptionKey" to error?.message,
            "NSLocalizedFailureReasonErrorKey" to "Failed to play the video.",
            "NSLocalizedRecoverySuggestionErrorKey" to "Please check the video source or try again later."
          ).toString()
        )
      }

      override fun onMediaBuffering(currentProgress: Long, bufferedProgress: Long) {
        setSeekBarProgress(currentProgress, bufferedProgress)
        rctEvent.onMediaBuffering(
          TimeUnit.MILLISECONDS.toSeconds(currentProgress).toDouble(),
          TimeUnit.MILLISECONDS.toSeconds(bufferedProgress).toDouble()
        )
      }

      override fun onMediaBufferCompleted() {
        rctEvent.onMediaBufferCompleted()
      }

      override fun getMediaMetadata(mediaMetadata: MediaMetadata) {
        setVideoTitle(mediaMetadata.title.toString())
      }

      override fun onPlaybackStateEndedInvoked() {
        setThumbnailTranslateX(0f)
      }

      override fun onMediaEnded() {
        rctEvent.onMediaCompleted()
      }
    })
  }

  private fun setupReactConfigs() {
    viewTreeObserver.addOnGlobalLayoutListener(object :
      ViewTreeObserver.OnGlobalLayoutListener {
      override fun onGlobalLayout() {
        val gestureSeekValue =
          rctConfigs.get(RCTConfigs.Key.DOUBLE_TAP_TO_SEEK_VALUE) as Int
        val gestureSeekSuffix =
          rctConfigs.get(RCTConfigs.Key.DOUBLE_TAP_TO_SEEK_SUFFIX_LABEL)

        modifyConfigLeftGestureSeek(gestureSeekValue, gestureSeekSuffix.toString())
        modifyConfigRightGestureSeek(gestureSeekValue, gestureSeekSuffix.toString())

        viewTreeObserver.removeOnGlobalLayoutListener(this)
      }
    })
  }

  private fun toggleFullscreen() {
    hideOverlay(animated = false)
    timeoutControls()
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
        rctEvent.onMenuItemSelected(title, value.toString())
      }
    }
    popupMenu.show()
  }

  private fun timeoutControls() {
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
    val currentMediaItem = mediaPlayer.currentMediaItem
    val currentPosition = mediaPlayer.currentProgress
    val currentMetadata = currentMediaItem?.mediaMetadata

    if (currentMediaItem?.localConfiguration?.uri.toString() == url) {
      return
    }
    /*      val dataSourceFactory = DefaultDataSource.Factory(context)
          val newMediaItem = MediaItem.fromUri(url)
          val newMediaSource =
            DefaultMediaSourceFactory(dataSourceFactory).createMediaSource(newMediaItem)

          mediaPlayer.setMediaSource(newMediaSource, currentPosition)
          mediaPlayer.prepare()*/
    mediaPlayer.onMediaBuild(url, currentPosition, currentMetadata)
  }
}

