package com.rnvideoplayer

import com.rnvideoplayer.components.CustomBottomDialog
import android.annotation.SuppressLint
import android.view.View
import android.view.ViewGroup
import android.widget.RelativeLayout
import android.widget.TextView
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import androidx.media3.ui.TimeBar
import androidx.media3.ui.TimeBar.OnScrubListener
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.components.CustomDoubleTapSeek
import com.rnvideoplayer.components.CustomLoading
import com.rnvideoplayer.components.CustomPlayerControls
import com.rnvideoplayer.components.CustomSeekBar
import com.rnvideoplayer.components.PopUpMenu
import com.rnvideoplayer.components.ThumbnailPreview
import com.rnvideoplayer.events.Events
import com.rnvideoplayer.exoPlayer.MediaPlayerInteractionHandle
import com.rnvideoplayer.helpers.MutableMapLongManager
import com.rnvideoplayer.helpers.RNVideoHelpers
import com.rnvideoplayer.helpers.TimeUnitManager
import com.rnvideoplayer.helpers.TimeoutWork
import com.rnvideoplayer.utils.fadeIn
import com.rnvideoplayer.utils.fadeOut
import java.util.concurrent.TimeUnit

@UnstableApi
@SuppressLint(
  "ViewConstructor",
  "UseCompatLoadingForDrawables",
  "ResourceType",
  "MissingInflatedId",
  "ClickableViewAccessibility"
)
class RNVideoPlayerView(private val context: ThemedReactContext) : PlayerView(context) {
  var mainView = this
  val mediaPlayer = MediaPlayerInteractionHandle(context, this)
  private val exoPlayer = mediaPlayer.exoPlayer

  private val videoPlayerView = mediaPlayer.getVideoPlayerView()
  private val helper = RNVideoHelpers()
  private var menusData: MutableSet<String> = mutableSetOf()

  private val timeoutWork = TimeoutWork()

  private val timeBar = CustomSeekBar(this)
  private val loading = CustomLoading(context, this)
  private val thumbnail = ThumbnailPreview(this)
  private val playerController = CustomPlayerControls(context, this)
  private val timeUnitHandler = TimeUnitManager()

  private var isVisibleControl: Boolean = false
  private var isFullScreen: Boolean = false
  private var isSeeking: Boolean = false
  private var started: Boolean = false

  private var doubleTapSuffixLabel: String = "seconds"
  private var doubleTapValue: Long = 15000

  private val overlayView: RelativeLayout
//  private var castPlayer: CastPlayer

  private var timeCodesDuration: TextView
  private var event = Events(context)

  private var leftDoubleTap = CustomDoubleTapSeek(
    context, this, false
  )
  private var rightDoubleTap = CustomDoubleTapSeek(
    context, this, true
  )


  init {
    rightDoubleTapGesture()
    leftDoubleTapGesture()
//    customPlayer.init()
//    val castContext = CastContext.getSharedInstance(context)
//    val mediaRouteButton = findViewById<MediaRouteButton>(R.id.media_route_button)

//    CastButtonFactory.setUpMediaRouteButton(context, mediaRouteButton)
    AspectRatioFrameLayout.RESIZE_MODE_FILL.also { resizeMode = it }
    overlayView = findViewById(R.id.overlay_controls)

//    castPlayer = CastPlayer(castContext)

//    timeCodesPosition = findViewById(R.id.time_codes_position)
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
            if (!started) {
              started = true
              timeBar.build(exoPlayer.duration)
              timeCodesDuration.text = helper.createTimeCodesFormatted(exoPlayer.duration)

              event.send(EventNames.videoLoaded, mainView, Arguments.createMap().apply {
                putDouble("duration", timeUnitHandler.toSecondsDouble(exoPlayer.duration))
              })
              timeoutControls()
              buildThumbnails()
            }
          }

          Player.STATE_ENDED -> {
            playerController.setVisibilityReplayButton(true)
            playerController.setVisibilityPlayPauseButton(false)
          }

          Player.STATE_IDLE -> {}
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
        exoPlayer.isPlaying -> {
          exoPlayer.pause()
          timeoutWork.cancelTimer()
        }

        else -> {
          timeoutControls()
          exoPlayer.play()
        }
      }
      playerController.morphPlayPause(exoPlayer.isPlaying)
      event.send(EventNames.videoPlayPauseStatus, this, Arguments.createMap().apply {
        putBoolean("isPlaying", exoPlayer.isPlaying)
      })
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

    videoPlayerView.setOnClickListener {
      onToggleControlsVisibility()
    }

    playerController.setSettingsButtonClickListener { viewer ->
      showPopUp(viewer)
    }

    playerController.setReplayButtonClickListener {
      exoPlayer.seekTo(0)
      thumbnail.translationX = 0F
      playerController.setVisibilityReplayButton(false)
    }

    //TODO: need implement cast
//    castPlayer.setSessionAvailabilityListener(object : SessionAvailabilityListener {
//      override fun onCastSessionAvailable() {
//        exoPlayer.currentMediaItem?.let { castPlayer.setMediaItem(it) }
//        exoPlayer.pause()
//      }
//
//      override fun onCastSessionUnavailable() {
//        exoPlayer.play()
//      }
//    })


    startPlaybackProgressUpdater()
  }

  private fun buildThumbnails() {
    if (mediaPlayer.thumbnailUrl.isNotBlank()) {
      thumbnail.generatingThumbnailFrames(mediaPlayer.thumbnailUrl)
    }
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

  private fun onTranslateXThumbnail(currentSeekPoint: Long): Float {
    var translateX = 16.0F
    if (currentSeekPoint.toFloat() + thumbnail.width / 2 >= timeBar.width.toFloat()) {
      translateX = (timeBar.width.toFloat() - thumbnail.width) - 16
    } else if (currentSeekPoint.toFloat() >= thumbnail.width / 2 && currentSeekPoint.toFloat() + thumbnail.width / 2 < timeBar.width.toFloat()) {
      translateX = currentSeekPoint.toFloat() - thumbnail.width / 2
    }

    return translateX
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

//    timeCodesPosition.text = helper.createTimeCodesFormatted(position)
    timeBar.update(position, buffered)
    event.send(EventNames.videoProgress, this, Arguments.createMap().apply {
      putDouble("progress", TimeUnit.MILLISECONDS.toSeconds(position).toDouble())
      putDouble("buffering", TimeUnit.MILLISECONDS.toSeconds(buffered).toDouble())
    })
  }

  private fun toggleFullScreen() {
    if (isFullScreen) layoutParams.height = currentHeight else layoutParams.height =
      ViewGroup.LayoutParams.MATCH_PARENT
    isFullScreen = !isFullScreen
    requestLayout()
  }

  private fun onToggleControlsVisibility() {
    if (!isVisibleControl) {
      showControls()
      if (exoPlayer.isPlaying) {
        timeoutControls()
      }
    } else {
      hideControls()
    }
  }

  private fun timeoutControls() {
    timeoutWork.cancelTimer()

    timeoutWork.createTask(4000) {
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

  fun getMenus(props: MutableSet<String>) {
    menusData = props
  }

  fun changeQuality(newQualityUrl: String) {
    mediaPlayer.changeVideoQuality(newQualityUrl)
  }

  fun changeRate(rate: Float) {
    mediaPlayer.changeRate(rate)
  }

  @SuppressLint("SetTextI18n")
  fun changeTapToSeekProps(props: ReadableMap?) {
    val suffixLabel = props?.getString("suffixLabel")
    val value = props?.getInt("value")

    if (suffixLabel != null) {
      doubleTapSuffixLabel = suffixLabel
    }
    if (value != null) {
      doubleTapValue = value.toLong()
    }
  }

  private fun rightDoubleTapGesture() {
    rightDoubleTap.tap(
      onSingleTap = { quantity ->
        updateRightDoubleTapText(rightDoubleTap, quantity)
        if (rightDoubleTap.effect.visibility == VISIBLE) {
          performSeekToNextPosition()
        } else {
          onToggleControlsVisibility()
        }
      },
      onDoubleTap = { quantity ->
        performSeekToNextPosition()
        updateRightDoubleTapText(rightDoubleTap, quantity)
        hideControls()
      }
    )
  }

  private fun leftDoubleTapGesture() {
    leftDoubleTap.tap(
      onSingleTap = { quantity ->
        updateDoubleTapText(leftDoubleTap, quantity)
        if (leftDoubleTap.effect.visibility == VISIBLE) {
          performSeekToPreviousPosition()
        } else {
          onToggleControlsVisibility()
        }
      },
      onDoubleTap = { quantity ->
        performSeekToPreviousPosition()
        updateDoubleTapText(leftDoubleTap, quantity)
        hideControls()
      })
  }

  @SuppressLint("SetTextI18n")
  private fun updateRightDoubleTapText(doubleTap: CustomDoubleTapSeek, quantity: Int) {
    doubleTap.doubleTapText.text = "${doubleTapValue.times(quantity)} $doubleTapSuffixLabel"
  }
  @SuppressLint("SetTextI18n")
  private fun updateDoubleTapText(doubleTap: CustomDoubleTapSeek, quantity: Int) {
    doubleTap.doubleTapText.text = "- ${doubleTapValue.times(quantity)} $doubleTapSuffixLabel"
  }

  private fun performSeekToNextPosition() {
    this.post {
      mediaPlayer.seekToNextPosition(doubleTapValue * 1000)
    }
  }

  private fun performSeekToPreviousPosition() {
    this.post {
      mediaPlayer.seekToPreviousPosition(doubleTapValue * 1000)
    }
  }

}
