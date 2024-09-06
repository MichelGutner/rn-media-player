package com.rnvideoplayer

import com.rnvideoplayer.components.CustomBottomDialog
import android.annotation.SuppressLint
import android.view.View
import android.view.ViewGroup
import android.widget.PopupMenu
import android.widget.RelativeLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.media3.cast.CastPlayer
import androidx.media3.cast.SessionAvailabilityListener
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import androidx.media3.ui.TimeBar
import androidx.media3.ui.TimeBar.OnScrubListener
import androidx.mediarouter.app.MediaRouteButton
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.ThemedReactContext
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.framework.CastContext
import com.rnvideoplayer.components.CustomContentDialog
import com.rnvideoplayer.components.CustomDoubleTapSeek
import com.rnvideoplayer.components.CustomLoading
import com.rnvideoplayer.components.CustomPlayerControls
import com.rnvideoplayer.components.CustomSeekBar
import com.rnvideoplayer.components.CustomThumbnailPreview
import com.rnvideoplayer.events.Events
import com.rnvideoplayer.exoPlayer.CustomExoPlayer
import com.rnvideoplayer.helpers.MutableMapLongManager
import com.rnvideoplayer.helpers.RNVideoHelpers
import com.rnvideoplayer.helpers.ReadableMapManager
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
class RNVideoPlayerView(context: ThemedReactContext) : PlayerView(context) {
  private val customPlayer = CustomExoPlayer(context, this)
  private val exoPlayer = customPlayer.getExoPlayer()
  private val overlayController = customPlayer.getOverlayView()
  private val helper = RNVideoHelpers()
  private var menusData: MutableSet<String> = mutableSetOf()

  private val timeBar = CustomSeekBar(this)
  private val loading = CustomLoading(context, this)
  private val thumbnail = CustomThumbnailPreview(this)
  private val dialog = CustomBottomDialog(context)
  private val playerController = CustomPlayerControls(context, this)
  private val readableManager = ReadableMapManager.getInstance()
  private val mutableMapLongManager = MutableMapLongManager.getInstance()

  private var isVisibleControl: Boolean = false
  private var isFullScreen: Boolean = false
  private var isSeeking: Boolean = false
  private val overlayView: RelativeLayout
  private lateinit var castPlayer: CastPlayer


  private var timeCodesPosition: TextView
  private var timeCodesDuration: TextView
  private var contentDialog = CustomContentDialog(context, dialog)

  private var event = Events(context)

  private var leftDoubleTap = CustomDoubleTapSeek(
    context, this, R.id.double_tap_view, R.id.double_tap, R.id.double_tap_text, false
  )
  private var rightDoubleTap = CustomDoubleTapSeek(
    context, this, R.id.double_tap_right_view, R.id.double_tap_2, R.id.double_tap_text_2, true
  )


  init {
    customPlayer.init()
    val castContext = CastContext.getSharedInstance(context)
    val mediaRouteButton = findViewById<MediaRouteButton>(R.id.media_route_button)

    CastButtonFactory.setUpMediaRouteButton(context, mediaRouteButton)
    AspectRatioFrameLayout.RESIZE_MODE_FILL.also { resizeMode = it }
    overlayView = findViewById(R.id.overlay_controls)

    castPlayer = CastPlayer(castContext)

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
        exoPlayer.isPlaying -> exoPlayer.pause()
        else -> exoPlayer.play()
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

    overlayController.setOnClickListener {
      onToggleControlsVisibility()
    }

    leftDoubleTap.tap({
      if (leftDoubleTap.effect.visibility == VISIBLE) {
        customPlayer.seekToPreviousPosition(15000)
      } else {
        onToggleControlsVisibility()
      }
    }, {
      hideControls()
      customPlayer.seekToPreviousPosition(15000)
    })

    rightDoubleTap.tap({
      if (rightDoubleTap.effect.visibility == VISIBLE) {
        customPlayer.seekToNextPosition(15000)
      } else {
        onToggleControlsVisibility()
      }
    }, {
      rightDoubleTap.effect.fadeIn(100)
      hideControls()
      customPlayer.seekToNextPosition(15000)
    })

    playerController.setSettingsButtonClickListener { viewer ->
      showPopUp(viewer)
    }
    playerController.setReplayButtonClickListener {
      exoPlayer.seekTo(0)
      thumbnail.translationX = 0F
      playerController.setVisibilityReplayButton(false)
    }

    castPlayer.setSessionAvailabilityListener(object : SessionAvailabilityListener {
      override fun onCastSessionAvailable() {
        exoPlayer.currentMediaItem?.let { castPlayer.setMediaItem(it) }
        exoPlayer.pause()
      }

      override fun onCastSessionUnavailable() {
        exoPlayer.play()
      }
    })

    runnable()
  }

  private fun showPopUp(view: View) {
    val popup = PopupMenu(context, view)
    menusData.forEach { menuItemTitle ->
      val item = popup.menu.add(menuItemTitle)
      item.icon = ContextCompat.getDrawable(context, R.drawable.arrow_forward)
      item.setOnMenuItemClickListener { menuItem ->
        val option = readableManager.getReadableMapProps(menuItem.title.toString())
        contentDialog.showOptionsDialog(option, "") { _, value ->
          event.send(EventNames.menuItemSelected, this, Arguments.createMap().apply {
            putString("name", menuItemTitle)
            putString("value", value.toString())
          })
        }
        true
      }
    }
    popup.inflate(R.menu.popup_menu)
    popup.gravity.also { popup.gravity = 5 }
    popup.show()
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
    val updateSeekBarTask = (object : Runnable {
      override fun run() {
        if (exoPlayer.playWhenReady && exoPlayer.isPlaying) {
          updateTimeBar()
        }
        postDelayed(this, updateIntervalMs)
      }
    })
    post(updateSeekBarTask)
  }

  fun setMediaItem(url: String) {
    val startTime = mutableMapLongManager.getMutableMapProps("startTime")
    customPlayer.buildMediaItem(url, startTime)
    thumbnail.generatingThumbnailFrames(url)
  }

//  fun releasePlayer() {
//    exoPlayer.release()
//  }

  private fun updateTimeBar() {
    val position = exoPlayer.contentPosition
    val buffered = exoPlayer.contentBufferedPosition

    timeCodesPosition.text = helper.createTimeCodesFormatted(position)
    timeBar.update(position, buffered)
  }

  private fun toggleFullScreen() {
    val params = this.layoutParams
    if (isFullScreen) {
      params.width = ViewGroup.LayoutParams.MATCH_PARENT
      params.height = currentHeight
    } else {
      params.width = ViewGroup.LayoutParams.MATCH_PARENT
      params.height = ViewGroup.LayoutParams.MATCH_PARENT
    }
    this.layoutParams = params
    isFullScreen = !isFullScreen

    this.requestLayout()
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

  fun getMenus(props: MutableSet<String>) {
    menusData = props
  }
  fun changeQuality(newQualityUrl: String) {
    customPlayer.changeVideoQuality(newQualityUrl)
  }
}
