package com.rnvideoplayer

import android.annotation.SuppressLint
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.net.Uri
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver.OnGlobalLayoutListener
import android.view.WindowManager
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.TimeBar
import androidx.media3.ui.TimeBar.OnScrubListener
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.ui.components.PopUpMenu
import com.rnvideoplayer.events.Events
import com.rnvideoplayer.helpers.SharedStore
import com.rnvideoplayer.helpers.TimeUnitManager
import com.rnvideoplayer.helpers.TimeoutWork
import com.rnvideoplayer.ui.VideoPlayerView
import com.rnvideoplayer.ui.components.CastPlayerView
import java.util.concurrent.TimeUnit

@OptIn(UnstableApi::class)
@SuppressLint("viewConstructor")
class RNVideoPlayerView(val context: ThemedReactContext) : VideoPlayerView(context) {
  private val exoPlayer = ExoPlayer.Builder(context).build()
  private val activity = context.currentActivity
  private val castPlayer = CastPlayerView(context, exoPlayer)

  private var menusData: MutableSet<String> = mutableSetOf()
  private val event = Events(context)
  private val timeUnitHandler = TimeUnitManager()
  private var started: Boolean = false
  private var isSeeking: Boolean = false
  private var aspectRatio: Float = 1.5f
  private var autoOrientationOnFullscreen = false

  private val timeoutWork = TimeoutWork()

  init {
//    viewControls.mainLayout.addView(castPlayer)
    viewTreeObserver.addOnGlobalLayoutListener(object : OnGlobalLayoutListener {
      override fun onGlobalLayout() {
        weakActivity.get() ?: return
        autoOrientationOnFullscreen =
          SharedStore.getInstance().getBoolean("autoOrientationOnFullscreen") ?: false
        viewTreeObserver.removeOnGlobalLayoutListener(this)
      }
    })
    this.post {
      startPlaybackProgressUpdater()
    }

    this.setFullscreenOnClickListener {
      toggleFullScreen()
    }

    this.setPlayPauseOnClickListener {
      playPauseManager()
    }
    this.setReplayOnClickListener {
      resetPlayer()
    }

    this.setMenuOnClickListener { viewer ->
      showPopUp(viewer)
    }

    this.playbackViewClickListener {
      toggleOverlay()
    }

    this.setLeftDoubleTapListener({
      if (viewControls.leftDoubleTap.doubleTapBackground.visibility == VISIBLE) {
        exoPlayer.seekTo(exoPlayer.contentPosition - it)
      } else {
        toggleOverlay()
      }
    }, {
      exoPlayer.seekTo(exoPlayer.contentPosition - it)
      viewControls.hideControls()

    })

    this.setRightDoubleTapListener({
      if (viewControls.rightDoubleTap.doubleTapBackground.visibility == VISIBLE) {
        exoPlayer.seekTo(exoPlayer.contentPosition + it)
      } else {
        toggleOverlay()
      }
    }, {
      exoPlayer.seekTo(exoPlayer.contentPosition + it)
      viewControls.hideControls()
    })

    exoPlayer.addListener(object : Player.Listener {
      override fun onPlaybackStateChanged(playbackState: Int) {
        super.onPlaybackStateChanged(playbackState)
        when (playbackState) {
          Player.STATE_READY -> {
            hideLoading()
            viewControls.timeBar.visibility = VISIBLE
            castPlayer.visibility = VISIBLE

            if (!started) {
              started = true
              viewControls.timeBar.build(exoPlayer.duration)
              event.send(
                EventNames.videoLoaded,
                this@RNVideoPlayerView,
                Arguments.createMap().apply {
                  putDouble("duration", timeUnitHandler.toSecondsDouble(exoPlayer.duration))
                  putBoolean("loaded", true)
                })
              timeoutControls()
            }
          }

          Player.STATE_BUFFERING -> {
            postDelayed({
              showLoading()
            }, 100)
            viewControls.timeBar.visibility = INVISIBLE
            castPlayer.visibility = INVISIBLE

            event.send(
              EventNames.videoBuffering,
              this@RNVideoPlayerView,
              Arguments.createMap().apply {
                putBoolean("buffering", true)
              })
          }

          Player.STATE_ENDED -> {
            post {
              viewControls.playPauseButton.visibility = INVISIBLE
              viewControls.replayButton.visibility = VISIBLE
            }
            event.send(
              EventNames.videoCompleted,
              this@RNVideoPlayerView,
              Arguments.createMap().apply {
                putBoolean("completed", true)
              })
            postInvalidate()
          }

          Player.STATE_IDLE -> {}
        }
      }

      override fun onPlayerError(error: PlaybackException) {
        event.send(
          EventNames.videoErrorStatus,
          this@RNVideoPlayerView,
          Arguments.createMap().apply {
            putString("error", error.cause.toString())
            putDouble("code", error.errorCode.toDouble())
            putString("userInfo", error.message)
            putString("description", error.stackTrace.toString())
            putString("failureReason", error.errorCodeName)
          })
      }
    })

    viewControls.timeBar.onScrubListener(object : OnScrubListener {
      override fun onScrubStart(timeBar: TimeBar, position: Long) {
        isSeeking = true
        hideButtons()
        viewControls.thumbnails.show()
        timeoutWork.cancelTimer()
      }


      override fun onScrubMove(scrubTimeBar: TimeBar, position: Long) {
        val duration = TimeUnit.MILLISECONDS.toSeconds(exoPlayer.duration)
        val seconds = TimeUnit.MILLISECONDS.toSeconds(position)
        val intervalInSeconds = TimeUnit.MILLISECONDS.toSeconds(viewControls.thumbnails.interval)
        val index = (seconds / intervalInSeconds).toInt()
        val currentSeekPoint =
          ((((seconds * 100) / duration) * viewControls.timeBar.timeBarWidth) / 100)
        viewControls.thumbnails.getCurrentPlayerPosition(position)

        if (index < viewControls.thumbnails.bitmaps.size) {
          viewControls.thumbnails.setCurrentImageBitmapByIndex(index)
          viewControls.thumbnails.translationXThumbnailView =
            onTranslateXThumbnail(currentSeekPoint)
        }
      }

      override fun onScrubStop(timeBar: TimeBar, position: Long, canceled: Boolean) {
        if (!canceled) {
          exoPlayer.seekTo(position)
          viewControls.thumbnails.hide()
          isSeeking = false
          timeoutControls()
          showButtons()
        }
      }
    })
  }

  private fun toggleOverlay() {
    if (viewControls.overlayView.visibility == VISIBLE) {
      viewControls.hideControls()
    } else {
      viewControls.showControls()
      if (exoPlayer.isPlaying) {
        timeoutControls()
      }
    }
  }

  fun build(source: ReadableMap?) {
    val url = source?.getString("url") as String
    val startTime = source.getDouble("startTime")
    val thumbnailProps = source.getMap("thumbnails")

    val mediaItem = MediaItem.fromUri(Uri.parse(url))
    exoPlayer.setMediaItem(mediaItem, (startTime * 1000).toLong())

    exoPlayer.prepare()
    this.player = exoPlayer

    val thumbnailUrl = thumbnailProps?.getString("url") as String
    val enabled = thumbnailProps.getBoolean("enabled")

    if (enabled) {
      if (thumbnailUrl.isNotEmpty()) {
        viewControls.thumbnails.generatingThumbnailFrames(thumbnailUrl)
      }
    }
  }

  fun changeVideoQuality(newQualityUrl: String) {
    val currentMediaItem = exoPlayer.currentMediaItem
    val currentPosition = exoPlayer.currentPosition

    if (currentMediaItem?.localConfiguration?.uri.toString() == newQualityUrl) {
      return
    }

    val dataSourceFactory = DefaultDataSource.Factory(context)
    val newMediaItem = MediaItem.fromUri(newQualityUrl)
    val newMediaSource =
      DefaultMediaSourceFactory(dataSourceFactory).createMediaSource(newMediaItem)

    exoPlayer.setMediaSource(newMediaSource, currentPosition)
    exoPlayer.prepare()
  }

  fun changeRate(rate: Float) {
    exoPlayer.setPlaybackSpeed(rate)
  }

  fun autoPlay(autoPlay: Boolean?) {
    exoPlayer.playWhenReady = autoPlay ?: true
  }

  fun changeResizeMode(ratio: Float) {
    aspectRatio = ratio
    setAspectRatio(aspectRatio)
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    exoPlayer.release()
    detachPlayerWindow()
  }

  private fun detachPlayerWindow() {
    val activity = context.currentActivity ?: return

    (aspectRatioFrameLayout.parent as? ViewGroup)?.removeView(aspectRatioFrameLayout)
    (viewControls.parent as? ViewGroup)?.removeView(viewControls)

    activity.window.apply {
      decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
      clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
    }
    activity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
    aspectRatioFrameLayout.requestLayout()
    aspectRatioFrameLayout.postInvalidate()
  }

  private fun startPlaybackProgressUpdater() {
    val updateIntervalMs = 1000L
    val updateSeekBarTask = (object : Runnable {
      override fun run() {
        if (exoPlayer.isPlaying) {
          updateTimeBar()
        }
        postDelayed(this, updateIntervalMs)
      }
    })
    post(updateSeekBarTask)
  }

  private fun updateTimeBar() {
    val position = exoPlayer.contentPosition
    val buffered = exoPlayer.contentBufferedPosition

    viewControls.timeBar.update(position, buffered)
    event.send(EventNames.videoProgress, this, Arguments.createMap().apply {
      putDouble("progress", TimeUnit.MILLISECONDS.toSeconds(position).toDouble())
      putDouble("buffering", TimeUnit.MILLISECONDS.toSeconds(buffered).toDouble())
    })
    if (buffered == exoPlayer.duration) {
      event.send(EventNames.videoBufferCompleted, this, Arguments.createMap().apply {
        putBoolean("completed", true)
      })
    }
  }

  private fun onTranslateXThumbnail(currentSeekPoint: Long): Float {
    val timeBarWidth = viewControls.timeBar.timeBarWidth.toFloat() + width * 0.10F
    val thumbWidth = viewControls.thumbnails.thumbWidth.toFloat()

    var translateX = 16.0F
    if ((currentSeekPoint.toFloat() + thumbWidth / 2) + width * 0.10F >= timeBarWidth) {
      translateX = (timeBarWidth - thumbWidth) - width * 0.10F
    } else if (currentSeekPoint.toFloat() >= thumbWidth / 2 && currentSeekPoint.toFloat() + thumbWidth / 2 < timeBarWidth) {
      translateX = currentSeekPoint.toFloat() - thumbWidth / 2
    }

    return translateX
  }

  private fun showPopUp(view: View) {
    val popupMenu by lazy {
      PopUpMenu(menusData, context, view) { title, value ->
        event.send(EventNames.menuItemSelected, this, Arguments.createMap().apply {
          putString("name", title)
          putString("value", value.toString())
        })
      }
    }
    popupMenu.show()
  }

  private fun toggleFullScreen() {
    if (isFullscreen) {
      exitFromFullScreen()
    } else {
      enterInFullScreen()
    }

    if (autoOrientationOnFullscreen) {
      if (resources?.configuration?.orientation == Configuration.ORIENTATION_PORTRAIT && isFullscreen) {
        activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
      } else {
        activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
      }
    }
  }

  private fun playPauseManager() {
    when {
      exoPlayer.isPlaying -> {
        exoPlayer.pause()
        timeoutWork.cancelTimer()
      }

      else -> {
        timeoutControls()
        exoPlayer.play()
      }
    }
    event.send(EventNames.videoPlayPauseStatus, this, Arguments.createMap().apply {
      putBoolean("isPlaying", exoPlayer.isPlaying)
    })
    viewControls.updatePlayPauseIcon(player?.isPlaying ?: true)
  }

  private fun timeoutControls() {
    timeoutWork.cancelTimer()

    timeoutWork.createTask(4000) {
      viewControls.hideControls()
    }

  }

  private fun resetPlayer() {
    exoPlayer.seekTo(0)
    viewControls.thumbnails.translationX = 0F
    viewControls.replayButton.visibility = INVISIBLE
  }

  fun getMenus(props: MutableSet<String>) {
    menusData = props
  }
}
