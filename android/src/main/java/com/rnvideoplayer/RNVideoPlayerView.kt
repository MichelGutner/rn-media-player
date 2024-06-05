package com.rnvideoplayer

import com.rnvideoplayer.components.CustomBottomDialog
import android.annotation.SuppressLint
import android.view.GestureDetector
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.RelativeLayout
import android.widget.TextView
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import androidx.media3.ui.TimeBar
import androidx.media3.ui.TimeBar.OnScrubListener
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.components.CustomContentDialog
import com.rnvideoplayer.components.CustomDoubleTapSeek
import com.rnvideoplayer.components.CustomLoading
import com.rnvideoplayer.components.CustomPlayerControls
import com.rnvideoplayer.components.CustomSeekBar
import com.rnvideoplayer.components.CustomThumbnailPreview
import com.rnvideoplayer.exoPlayer.CustomExoPlayer
import com.rnvideoplayer.helpers.RNVideoHelpers
import com.rnvideoplayer.helpers.ReadableMapManager
import com.rnvideoplayer.utils.fadeIn
import com.rnvideoplayer.utils.fadeOut
import java.util.Timer
import java.util.TimerTask
import java.util.concurrent.TimeUnit

@UnstableApi
@SuppressLint(
  "ViewConstructor",
  "UseCompatLoadingForDrawables",
  "ResourceType",
  "MissingInflatedId",
  "ClickableViewAccessibility"
)
class RNVideoPlayerView(context: ThemedReactContext) : PlayerView(context) {
  private val customPlayer = CustomExoPlayer(context, this)
  private val exoPlayer = customPlayer.getExoPlayer()
  private val overlayController = customPlayer.getOverlayView()
  private val parentView = customPlayer.getParentView()
  private val helper = RNVideoHelpers()
  private var settingsProps: ReadableArray? = null

  private val timeBar = CustomSeekBar(this)
  private val loading = CustomLoading(context, this)
  private val thumbnail = CustomThumbnailPreview(this)
  private val dialog = CustomBottomDialog(context)
  private val playerController = CustomPlayerControls(context, this)
  private val readableManager = ReadableMapManager.getInstance()

  private var isVisibleControl: Boolean = true
  private var isFullScreen: Boolean = false
  private var isSeeking: Boolean = false
  private val overlayView: RelativeLayout


  private var timeCodesPosition: TextView
  private var timeCodesDuration: TextView
  private var contentDialog = CustomContentDialog(context, dialog)

  private var selectedQuality: String? = null
  private var selectedSpeed: String? = null
  private var timer = Timer()
  private var resetTimerTask: TimerTask? = null
  private var leftDoubleTap = CustomDoubleTapSeek(
    context,
    this,
    R.id.double_tap_view,
    R.id.double_tap,
    R.id.double_tap_text,
    false
  )
  private var rightDoubleTap = CustomDoubleTapSeek(
    context, this, R.id.double_tap_right_view,
    R.id.double_tap_2,
    R.id.double_tap_text_2,
    true
  )


  init {
    customPlayer.init()
    AspectRatioFrameLayout.RESIZE_MODE_FIT.also { resizeMode = it }
    overlayView = findViewById(R.id.overlay_controls)


    timeCodesPosition = findViewById(R.id.time_codes_position)
    timeCodesDuration = findViewById(R.id.time_codes_duration)

    exoPlayer.addListener(object : Player.Listener {
      override fun onPlaybackStateChanged(playbackState: Int) {
        super.onPlaybackStateChanged(playbackState)
        when (playbackState) {
          Player.STATE_BUFFERING -> {
            playerController.setVisibilityPlayPauseButton(false)
            loading.show()
          }

          Player.STATE_READY -> {
            playerController.setVisibilityPlayPauseButton(true)
            loading.hide()
            timeBar.build(exoPlayer.duration)
            timeCodesDuration.text = helper.createTimeCodesFormatted(exoPlayer.duration)
          }

          Player.STATE_ENDED -> {
            playerController.setVisibilityReplayButton(true)
            playerController.setVisibilityPlayPauseButton(false)
          }

          Player.STATE_IDLE -> {
            println("STATE_IDLE")
//            exoPlayer.videoChangeFrameRateStrategy
          }
        }

        updateTimeBar()
      }

      override fun onPlayerError(error: PlaybackException) {
//        println("Error: ${error.errorCode} ${error.message} ${error.localizedMessage} ${error.stackTrace} ${error.cause} ${error.errorCodeName} ${error.timestampMs}")
        // handle errors
      }
    })

    playerController.setPlayPauseButtonClickListener {
      when {
        exoPlayer.isPlaying -> exoPlayer.pause()
        else -> exoPlayer.play()
      }
      playerController.morphPlayPause(exoPlayer.isPlaying)
    }

    playerController.setFullScreenButtonClickListener {
      playerController.morphFullScreen(isFullScreen)
      toggleFullScreen()
    }

    timeBar.onScrubListener(object : OnScrubListener {
      override fun onScrubStart(timeBar: TimeBar, position: Long) {
        isSeeking = true
      }

      override fun onScrubMove(scrubTimeBar: TimeBar, position: Long) {
        val seconds = TimeUnit.MILLISECONDS.toSeconds(position)
        val duration = TimeUnit.MILLISECONDS.toSeconds(exoPlayer.duration)
        val intervalInSeconds = TimeUnit.MILLISECONDS.toSeconds(thumbnail.interval)
        val index = (seconds / intervalInSeconds).toInt()
        val currentSeekPoint = ((((seconds * 100) / duration) * timeBar.width) / 100)
        if (index < thumbnail.bitmaps.size) {
          thumbnail.setCurrentImageBitmapByIndex(index)
          thumbnail.translationX = onTranslateXThumbnail(currentSeekPoint)
        }
        thumbnail.getCurrentPlayerPosition(helper.createTimeCodesFormatted(position))
        thumbnail.show()
      }

      override fun onScrubStop(timeBar: TimeBar, position: Long, canceled: Boolean) {
        if (!canceled) {
          exoPlayer.seekTo(position)
          thumbnail.hide()
          isSeeking = false
          playerController.setVisibilityReplayButton(false)
        }
      }
    })

    overlayController.setOnClickListener {
      onToggleControlsVisibility()
    }

    leftDoubleTap.tap({
      resetTimerTask?.cancel()
      if (leftDoubleTap.effect.visibility == VISIBLE) {
        onTimerTask() {
          leftDoubleTap.effect.fadeOut(100)
        }
        customPlayer.seekToPreviousPosition(15000)
      } else {
        onToggleControlsVisibility()
      }
    }, {
      resetTimerTask?.cancel()
      hideControls()
      onTimerTask() {
        leftDoubleTap.effect.fadeOut(10)
      }
      customPlayer.seekToPreviousPosition(15000)
    })
    rightDoubleTap.tap({
      resetTimerTask?.cancel()
      if (rightDoubleTap.effect.visibility == VISIBLE) {
        onTimerTask() {
          rightDoubleTap.effect.fadeOut(100)
        }
        customPlayer.seekToNextPosition(15000)
      } else {
        onToggleControlsVisibility()
      }
    }, {
      rightDoubleTap.effect.fadeIn(100)
      resetTimerTask?.cancel()
      hideControls()

      onTimerTask() {
        rightDoubleTap.effect.fadeOut(100)
      }
      customPlayer.seekToNextPosition(15000)
    })

    playerController.setSettingsButtonClickListener {
      val qualities = readableManager.getReadableMapProps("qualities")
      val data = qualities?.getArray("data")
      val initialSelected = qualities?.getString("initialSelected")

      if (selectedQuality.isNullOrEmpty()) {
        selectedQuality = initialSelected
      }

      val speeds = readableManager.getReadableMapProps("speeds")
      val dataSpeeds = speeds?.getArray("data")
      val initialSelectedSpeed = speeds?.getString("initialSelected")

      if (selectedSpeed.isNullOrEmpty()) {
        selectedSpeed = initialSelectedSpeed
      }


      val view = LayoutInflater.from(context).inflate(R.layout.custom_dialog, null)
      val currentQualitySelected = view.findViewById<TextView>(R.id.currentQualityTextView)
      val currentSpeedSelected = view.findViewById<TextView>(R.id.currentPlaybackSpeedTextView)

      currentQualitySelected.text = selectedQuality
      currentSpeedSelected.text = selectedSpeed

      dialog.setContentView(view)
      dialog.show()

      val qualitiesLayout: LinearLayout = view.findViewById(R.id.qualitiesLayout)
      val speedsLayout: LinearLayout = view.findViewById(R.id.speedsLayout)

      qualitiesLayout.setOnClickListener {
        dialog.dismiss()
        postDelayed({
          run {
            contentDialog.showOptionsDialog(data, selectedQuality) { name, value ->
              selectedQuality = name
              customPlayer.changeVideoQuality(value)
            }
          }
        }, 300)
      }


      speedsLayout.setOnClickListener {
        dialog.dismiss()
        postDelayed({
          run {
            contentDialog.showOptionsDialog(dataSpeeds, selectedSpeed) { name, value ->
              selectedSpeed = name
              exoPlayer.setPlaybackSpeed(value.toFloat())
            }
          }
        }, 300)
      }
    }

    playerController.setReplayButtonClickListener {
      exoPlayer.seekTo(0)
      thumbnail.translationX = 0F
      playerController.setVisibilityReplayButton(false)
    }

    runnable()
  }

  private fun onTranslateXThumbnail(currentSeekPoint: Long): Float {
    var translateX = 16.0F
    if (currentSeekPoint.toFloat() + thumbnail.width / 2 >= timeBar.width.toFloat()) {
      translateX = (timeBar.width.toFloat() - thumbnail.width) - 16
    } else if (currentSeekPoint.toFloat() >= thumbnail.width / 2 && currentSeekPoint.toFloat() + thumbnail.width / 2 < timeBar.width.toFloat()) {
      translateX = currentSeekPoint.toFloat() - thumbnail.width / 2
    }

    return translateX
  }

  private fun runnable() {
    val updateIntervalMs = 1000L
    val updateSeekBarTask = object : Runnable {
      override fun run() {
        if (exoPlayer.playWhenReady && exoPlayer.isPlaying) {
          updateTimeBar()
        }
        postDelayed(this, updateIntervalMs)
      }
    }
    post(updateSeekBarTask)
  }

  fun setMediaItem(url: String) {
    customPlayer.buildMediaItem(url)
    thumbnail.generatingThumbnailFrames(url)
  }

//  fun releasePlayer() {
//    exoPlayer.release()
//  }

  fun onTimerTask(resetDuration: Long = 1000, callback: () -> Unit) {
    resetTimerTask = object : TimerTask() {
      override fun run() {
        callback()
      }
    }
    timer.schedule(resetTimerTask, resetDuration)
  }

  private fun updateTimeBar() {
    val position = exoPlayer.contentPosition
    val buffered = exoPlayer.contentBufferedPosition

    timeCodesPosition.text = helper.createTimeCodesFormatted(position)
    timeBar.update(position, buffered)
  }

  private fun toggleFullScreen() {
    if (isFullScreen) {
      parentView.removeView(this)
      parentView.addView(this, ViewGroup.LayoutParams.MATCH_PARENT, currentHeight)
    } else {
      parentView.removeView(this)
      parentView.addView(
        this, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT
      )
    }
    isFullScreen = !isFullScreen
  }

  fun setCurrentHeight(height: Int) {
    currentHeight = height
  }

  private fun onToggleControlsVisibility() {
    if (!isVisibleControl) {
      showControls()
    } else {
      hideControls()
    }
  }

  private fun showControls() {
    isVisibleControl = true
    overlayView.fadeIn()
  }

  private fun hideControls() {
    isVisibleControl = false
    overlayView.fadeOut()
  }

  fun getSettingsProperties(props: ReadableMap) {
    settingsProps = props.getArray("data")
  }
}
