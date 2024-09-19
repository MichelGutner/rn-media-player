package com.rnvideoplayer

import android.annotation.SuppressLint
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
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
import com.rnvideoplayer.exoPlayer.MediaPlayerInteractionHandler
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
  val mediaPlayer = MediaPlayerInteractionHandler(context, this)
  private val exoPlayer = mediaPlayer.exoPlayer

  private val videoPlayerView = mediaPlayer.getVideoPlayerView()
  private val helper = RNVideoHelpers()
  private var menusData: MutableSet<String> = mutableSetOf()

  private val timeoutWork = TimeoutWork()

  private val timeBar = CustomSeekBar(this)
  private val loading = CustomLoading(context, this)
  private val controls = CustomPlayerControls(context, this)

  private val thumbnail by lazy { ThumbnailPreview(this) }

  private val timeUnitHandler = TimeUnitManager()

  private var isVisibleControl: Boolean = false
  private var isFullScreen: Boolean = false
  private var isSeeking: Boolean = false
  private var started: Boolean = false

  private var doubleTapSuffixLabel: String = "Seconds"
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
            controls.setVisibilityPlayPauseButton(false)
            loading.show()
            event.send(EventNames.videoBuffering, mainView, Arguments.createMap().apply {
              putBoolean("buffering", true)
            })
          }

          Player.STATE_READY -> {

            loading.hide()
            controls.setVisibilityPlayPauseButton(true)
//            event.send(EventNames.videoBuffering, mainView, Arguments.createMap().apply {
//              putBoolean("buffering", false)
//            })
//            event.send(EventNames.videoReady, mainView, Arguments.createMap().apply {
//              putBoolean("ready", true)
//            })
            if (!started) {
              started = true
              timeBar.build(exoPlayer.duration)
              timeCodesDuration.text = helper.createTimeCodesFormatted(exoPlayer.duration)
//              event.send(EventNames.videoLoaded, mainView, Arguments.createMap().apply {
//                putDouble("duration", timeUnitHandler.toSecondsDouble(exoPlayer.duration))
//              })
              timeoutControls()
              buildThumbnails()
            }
          }

          Player.STATE_ENDED -> {
            post {
              controls.setVisibilityReplayButton(true)
              controls.setVisibilityPlayPauseButton(false)
            }
//            event.send(EventNames.videoCompleted, mainView, Arguments.createMap().apply {
//              putBoolean("completed", true)
//            })
            postInvalidate()
          }

          Player.STATE_IDLE -> {}
        }

        updateTimeBar()
      }

      override fun onPlayerError(error: PlaybackException) {
        event.send(EventNames.videoErrorStatus, mainView, Arguments.createMap().apply {
          putString("error", error.cause.toString())
          putDouble("code", error.errorCode.toDouble())
          putString("userInfo", error.message)
          putString("description", error.stackTrace.toString())
          putString("failureReason", error.errorCodeName)
        })
      }
    })

    controls.setPlayPauseButtonClickListener {
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
      controls.morphPlayPause(exoPlayer.isPlaying)
      event.send(EventNames.videoPlayPauseStatus, this, Arguments.createMap().apply {
        putBoolean("isPlaying", exoPlayer.isPlaying)
      })
    }

    controls.setFullScreenButtonClickListener {
      controls.morphFullScreen(isFullScreen)
      toggleFullScreen()
    }

    timeBar.onScrubListener(object : OnScrubListener {
      override fun onScrubStart(timeBar: TimeBar, position: Long) {
        isSeeking = true
        controls.playPauseBackground.visibility = View.INVISIBLE
        controls.setVisibilitySettingsButton(false)
        thumbnail.show()
        timeoutWork.cancelTimer()
      }


      override fun onScrubMove(scrubTimeBar: TimeBar, position: Long) {
        val duration = TimeUnit.MILLISECONDS.toSeconds(exoPlayer.duration)
        val seconds = TimeUnit.MILLISECONDS.toSeconds(position)
        val intervalInSeconds = TimeUnit.MILLISECONDS.toSeconds(thumbnail.interval)
        val index = (seconds / intervalInSeconds).toInt()
        val currentSeekPoint = ((((seconds * 100) / duration) * timeBar.width) / 100)
        thumbnail.getCurrentPlayerPosition(helper.createTimeCodesFormatted(position))

        if (index < thumbnail.bitmaps.size) {
          thumbnail.setCurrentImageBitmapByIndex(index)
          thumbnail.translationX = onTranslateXThumbnail(currentSeekPoint)
        }
      }

      override fun onScrubStop(timeBar: TimeBar, position: Long, canceled: Boolean) {
        if (!canceled) {
          exoPlayer.seekTo(position)
          thumbnail.hide()
          isSeeking = false
          controls.setVisibilityReplayButton(false)
          controls.setVisibilitySettingsButton(true)
          timeoutControls()
          post {
            controls.playPauseBackground.visibility = View.VISIBLE
          }
        }
      }
    })

    videoPlayerView.setOnClickListener {
      onToggleControlsVisibility()
    }

    controls.setSettingsButtonClickListener { viewer ->
      showPopUp(viewer)
    }

    controls.setReplayButtonClickListener {
      exoPlayer.seekTo(0)
      thumbnail.view.translationX = 0F
      thumbnail.translationX = 0F
      controls.setVisibilityReplayButton(false)
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
    val timeBarWidth =
      timeBar.width.toFloat() + context.resources.displayMetrics.widthPixels * 0.10F
    var translateX = 16.0F
    if (currentSeekPoint.toFloat() + thumbnail.width / 2 >= timeBarWidth) {
      translateX = (timeBarWidth - thumbnail.width) - 16
    } else if (currentSeekPoint.toFloat() >= thumbnail.width / 2 && currentSeekPoint.toFloat() + thumbnail.width / 2 < timeBarWidth) {
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

  private var currentParent: ViewGroup? = null
  private var currentIndexInParent: Int = -1

  private fun toggleFullScreen() {
    val activity = context.currentActivity ?: return

    if (isFullScreen) {
      (this.parent as? ViewGroup)?.removeView(this)

      currentParent?.also { parent ->
        layoutParams = layoutParams.apply {
          height = ViewGroup.LayoutParams.WRAP_CONTENT
          width = ViewGroup.LayoutParams.WRAP_CONTENT
        }
        activity.window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_VISIBLE)
        activity.window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)

        parent.addView(this, currentIndexInParent)
      }
    } else {
      currentParent = this.parent as? ViewGroup
      currentIndexInParent = currentParent?.indexOfChild(this) ?: -1

      currentParent?.removeView(this)

      (activity.window?.decorView as ViewGroup).addView(this@RNVideoPlayerView).apply {
        layoutParams.apply {
          height = ViewGroup.LayoutParams.MATCH_PARENT
          width = ViewGroup.LayoutParams.MATCH_PARENT
        }
      }

      activity.window.decorView.systemUiVisibility =
        (View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or View.SYSTEM_UI_FLAG_LAYOUT_STABLE)

      activity.window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
    }

    this.requestLayout()
    this.postInvalidate()

    isFullScreen = !isFullScreen
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
      onSingleTap = {
        if (rightDoubleTap.doubleTapBackground.visibility == VISIBLE) {
          performSeekToNextPosition()
        } else {
          onToggleControlsVisibility()
        }
      }, onDoubleTap = {
        performSeekToNextPosition()
        hideControls()
      })
  }

  private fun leftDoubleTapGesture() {
    leftDoubleTap.tap(
      onSingleTap = {
        if (leftDoubleTap.doubleTapBackground.visibility == VISIBLE) {
          performSeekToPreviousPosition()
        } else {
          onToggleControlsVisibility()
        }
      }, onDoubleTap = {
        performSeekToPreviousPosition()
        hideControls()
      })
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
