package com.rnvideoplayer.mediaplayer.viewModels

import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.core.view.isVisible
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.TimeBar
import com.facebook.react.bridge.Arguments
import com.rnvideoplayer.mediaplayer.models.ReactEvents
import com.rnvideoplayer.fadeIn
import com.rnvideoplayer.fadeOut
import com.rnvideoplayer.helpers.TimeUnitManager
import com.rnvideoplayer.mediaplayer.models.MediaPlayerAdapter
import com.rnvideoplayer.mediaplayer.interfaces.IMediaPlayerControls
import com.rnvideoplayer.mediaplayer.models.ReactConfig
import com.rnvideoplayer.mediaplayer.models.ReactEventsName
import com.rnvideoplayer.mediaplayer.viewModels.components.FullscreenButton
import com.rnvideoplayer.mediaplayer.viewModels.components.PlayPauseButton
import com.rnvideoplayer.mediaplayer.viewModels.components.SeekBar
import com.rnvideoplayer.mediaplayer.viewModels.components.Title
import com.rnvideoplayer.mediaplayer.utils.Utils
import com.rnvideoplayer.mediaplayer.viewModels.components.DoubleTapSeek
import com.rnvideoplayer.mediaplayer.viewModels.components.TimeCodes
import com.rnvideoplayer.ui.components.Loading
import com.rnvideoplayer.ui.components.Thumbnails
import com.rnvideoplayer.withTranslationAnimation
import java.util.concurrent.TimeUnit



@UnstableApi
abstract class MediaPlayerControls(context: Context) : FrameLayout(context), IMediaPlayerControls {
  val controlsView = FrameLayout(context).apply {
    layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
  }

  protected var reactApplicationEvent : ReactEvents? = null
  protected var reactConfig: ReactConfig? = null
  private var timeUnitHandler = TimeUnitManager()
  private val mediaPlayer = MediaPlayerAdapter(context)

  private val overlayView = overlayView()
  private val loading by lazy { Loading(context) }
  private val playPauseButton by lazy { PlayPauseButton(context) }
  private val fullscreenButton by lazy { FullscreenButton(context) }
  private val seekBar by lazy { SeekBar(context) }
  private val title by lazy { Title(context) }
  private val timeCodes by lazy { TimeCodes(context) }
  private val thumbnails by lazy { Thumbnails(context) }

  private val mediaBottomControls = customFrameLayout()
  private val bottomVerticalControlsLayout = customLinearVerticalLayout()
  private val bottomHorizontalControlsLayout = customLinearHorizontalLayout()

  private var startScrubberPositionSeconds = 0
  private var startScrubberPositionPercent = 0

  private var isFullscreen = false
  private var isFinished = false

  val surfaceView = mediaPlayer.surfaceView
  val leftDoubleTapSeek by lazy { DoubleTapSeek(context, false) }
  val rightDoubleTapSeek by lazy { DoubleTapSeek(context, true) }

  init {
    setupReactConfigs()

    setupMediaPlayerCallbacks()
    setupComponents()
    seekBarListener()
  }

  open fun addEvents(reactEvents: ReactEvents?) {
    reactApplicationEvent = reactEvents
  }

  open fun addReactConfigs(config: ReactConfig) {
    this.reactConfig = config
  }

  private fun setupComponents() {
    playPauseButton.setOnClickListener {
      mediaPlayer.togglePlayPause()
    }
    fullscreenButton.setOnClickListener {
      toggleFullscreen()
    }

    leftDoubleTapSeek.onTapListener { value ->
      mediaPlayer.seekToWithLastPosition(-((value * 1000).toLong()))
    }
    rightDoubleTapSeek.onTapListener { value ->
      mediaPlayer.seekToWithLastPosition(((value * 1000).toLong()))
    }

    playPauseButton.setSize(dpToPx(70f))
    fullscreenButton.setSize(dpToPx(40f))

    bottomHorizontalControlsLayout.addView(thumbnails)
    bottomHorizontalControlsLayout.addView(fullscreenButton)

    bottomVerticalControlsLayout.addView(seekBar)
    bottomVerticalControlsLayout.addView(timeCodes)

    mediaBottomControls.addView(bottomHorizontalControlsLayout)
    mediaBottomControls.addView(bottomVerticalControlsLayout)


    overlayView.addView(title)
    overlayView.addView(playPauseButton)
    overlayView.addView(mediaBottomControls)

    controlsView.addView(leftDoubleTapSeek)
    controlsView.addView(rightDoubleTapSeek)

    controlsView.addView(overlayView)
    controlsView.addView(loading)
  }

  private fun setupMediaPlayerCallbacks() {
    mediaPlayer.addCallback(object : MediaPlayerAdapter.Callback {
      override fun onMediaLoaded(duration: Long) {
        seekBar.build(duration)
        timeCodes.updateDuration(duration)
        reactApplicationEvent?.send(ReactEventsName.MEDIA_READY,this@MediaPlayerControls, Arguments.createMap().apply {
          putDouble("duration", timeUnitHandler.toSecondsDouble(duration))
          putBoolean("loaded", true)
        })
        postDelayed({
          loading.fadeOut {
            controlsView.removeView(loading)
            controlsView.requestLayout()
          }
        }, 400)
      }

      override fun onPlaybackStateChanged(isPlaying: Boolean) {
        playPauseButton.updatePlayPauseIcon(isPlaying)
        reactApplicationEvent?.send(ReactEventsName.MEDIA_PLAY_PAUSE, this@MediaPlayerControls, Arguments.createMap().apply {
          putBoolean("isPlaying", isPlaying)
        })
      }

      override var shouldShowPlayPause: Boolean
        get() = true
        set(value) {}

      override fun onMediaError(error: PlaybackException?, mediaItem: MediaItem?) {
        val uri = mediaItem?.localConfiguration?.uri
        reactApplicationEvent?.send(
          ReactEventsName.MEDIA_ERROR,
          this@MediaPlayerControls,
          Arguments.createMap().apply {
            putString("domain", uri.toString())
            putString("error", error?.cause.toString())
            error?.errorCode?.let { putDouble("code", it.toDouble()) }
            putString("userInfo", mapOf(
              "NSLocalizedDescriptionKey" to error?.message,
              "NSLocalizedFailureReasonErrorKey" to "Failed to play the video.",
              "NSLocalizedRecoverySuggestionErrorKey" to "Please check the video source or try again later."
            ).toString())
          })
      }

      override fun onMediaBuffering(currentProgress: Long, bufferedProgress: Long) {
        seekBar.update(currentProgress, bufferedProgress)
        timeCodes.updatePosition(currentProgress)
        reactApplicationEvent?.send(ReactEventsName.MEDIA_PROGRESS, this@MediaPlayerControls, Arguments.createMap().apply {
          putDouble("progress", TimeUnit.MILLISECONDS.toSeconds(currentProgress).toDouble())
          putDouble("buffering", TimeUnit.MILLISECONDS.toSeconds(bufferedProgress).toDouble())
        })
      }

      override fun getMediaMetadata(mediaMetadata: MediaMetadata) {
        title.setTitle(mediaMetadata.title.toString())
      }

      override fun onPlaybackStateEndedInvoked() {
        thumbnails.translationXThumbnailView = 0f
      }
    })
  }

  private fun seekBarListener() {
    seekBar.onScrubListener(object : TimeBar.OnScrubListener {
      override fun onScrubStart(seekBar: TimeBar, position: Long) {
        val totalDurationSeconds = TimeUnit.MILLISECONDS.toSeconds(mediaPlayer.duration).toInt()
        startScrubberPositionSeconds = TimeUnit.MILLISECONDS.toSeconds(position).toInt()

        startScrubberPositionPercent = if (totalDurationSeconds > 0) {
          (startScrubberPositionSeconds * 100) / totalDurationSeconds
        } else {
          0
        }

       this@MediaPlayerControls.seekBar.animate().scaleX(1f).scaleY(1.5f).setDuration(500).start()
        thumbnails.show()
        hideControls()
      }

      override fun onScrubMove(seekBar: TimeBar, position: Long) {
        val duration = TimeUnit.MILLISECONDS.toSeconds(mediaPlayer.duration)
        val seconds = TimeUnit.MILLISECONDS.toSeconds(position)
        thumbnails.updatePosition(position)
        thumbnails.onTranslate(seconds.toDouble(), duration.toDouble(), this@MediaPlayerControls.seekBar.width)
      }

      override fun onScrubStop(seekBar: TimeBar, position: Long, canceled: Boolean) {
        val endScrubberPositionSeconds = TimeUnit.MILLISECONDS.toSeconds(position).toInt()
        val totalDurationSeconds = TimeUnit.MILLISECONDS.toSeconds(mediaPlayer.duration).toInt()

        val endScrubberPositionPercent = if (totalDurationSeconds > 0) {
          (endScrubberPositionSeconds * 100) / totalDurationSeconds
        } else {
          0
        }

        val startMap = Arguments.createMap().apply {
          putDouble("percent", startScrubberPositionPercent.toDouble())
          putDouble("seconds", startScrubberPositionSeconds.toDouble())
        }

        val endMap = Arguments.createMap().apply {
          putDouble("percent", endScrubberPositionPercent.toDouble())
          putDouble("seconds", endScrubberPositionSeconds.toDouble())
        }

        reactApplicationEvent?.send(ReactEventsName.MEDIA_SEEK_BAR, this@MediaPlayerControls, Arguments.createMap().apply {
          putMap("start", startMap)
          putMap("end", endMap)
        })

        thumbnails.hide()
        showControls()

        this@MediaPlayerControls.seekBar.animate().scaleX(1.0f).scaleY(1.0f).setDuration(500).start()
        val duration = TimeUnit.MILLISECONDS.toSeconds(mediaPlayer.duration)
        val seconds = TimeUnit.MILLISECONDS.toSeconds(position)

        if (seconds < duration) {
          isFinished = false
        }

        if (!canceled) {
          mediaPlayer.seekTo(position)
        }
      }
    })
  }

  private fun setupReactConfigs() {
    viewTreeObserver.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
      override fun onGlobalLayout() {

        val doubleTapSeekValue =
          ReactConfig.getInstance().get(ReactConfig.Keys.DOUBLE_TAP_TO_SEEK_VALUE) as Int
        val doubleTapSuffix = reactConfig?.get(ReactConfig.Keys.DOUBLE_TAP_TO_SEEK_SUFFIX_LABEL)
        leftDoubleTapSeek.tapValue = doubleTapSeekValue
        leftDoubleTapSeek.suffixLabel = doubleTapSuffix.toString()

        rightDoubleTapSeek.tapValue = doubleTapSeekValue
        rightDoubleTapSeek.suffixLabel = doubleTapSuffix.toString()

        viewTreeObserver.removeOnGlobalLayoutListener(this)
      }
    })
  }

  private fun toggleFullscreen() {
    onFullscreenMode(!isFullscreen)
    fullscreenButton.updateFullscreenIcon(!isFullscreen)
    isFullscreen = !isFullscreen
  }

  private fun overlayView(): FrameLayout {
    val padding = dpToPx(16f)

    val gradientDrawable = GradientDrawable(
      GradientDrawable.Orientation.TOP_BOTTOM,
      intArrayOf(Utils.COLOR_BLACK_ALPHA_05, Utils.COLOR_BLACK_ALPHA_02, Utils.COLOR_BLACK_ALPHA_05)
    )

    return FrameLayout(context).apply {
      background = gradientDrawable
      layoutParams = LayoutParams(
        LayoutParams.MATCH_PARENT,
        LayoutParams.MATCH_PARENT
      )
      setPadding(padding,padding,padding,padding)
    }
  }

  private fun dpToPx(dp: Float): Int {
    return TypedValue.applyDimension(
      TypedValue.COMPLEX_UNIT_DIP,
      dp,
      context.resources.displayMetrics
    ).toInt()
  }

  private fun customFrameLayout() : LinearLayout {
    return LinearLayout(context).apply {
      layoutParams = LayoutParams(
        LayoutParams.MATCH_PARENT,
        LayoutParams.WRAP_CONTENT,
      ).apply {
        orientation = LinearLayout.VERTICAL
      gravity = Gravity.BOTTOM
      }
    }
  }

  private fun customLinearVerticalLayout() : LinearLayout {
    return LinearLayout(context).apply {
      layoutParams = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.WRAP_CONTENT,
      ).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.BOTTOM
      }
    }
  }

  private fun customLinearHorizontalLayout() : LinearLayout {
    return LinearLayout(context).apply {
      layoutParams = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.WRAP_CONTENT,
      ).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.BOTTOM
      }
    }
  }

  private fun hideControls() {
    fullscreenButton.fadeOut()
    playPauseButton.fadeOut()
  }

  private fun showControls() {
    fullscreenButton.fadeIn()
    playPauseButton.fadeIn()
  }

  fun toggleOverlayVisibility() {
    if (overlayView.isVisible) {
      overlayView.fadeOut()
      bottomVerticalControlsLayout.withTranslationAnimation( 20f)
      title.withTranslationAnimation(-20f)
    } else {
      overlayView.fadeIn()
      bottomVerticalControlsLayout.withTranslationAnimation()
      title.withTranslationAnimation()
    }
  }

  fun mediaPlayerRelease() {
    mediaPlayer.release()
  }

  fun setupMediaPlayer(url: String, startTime: Long? = 0, metadata: MediaMetadata? = null) {
    mediaPlayer.onBuild(url, startTime, metadata)
  }

  fun onAutoPlay(autoPlayer: Boolean) {
    mediaPlayer.onAutoPlay(autoPlayer)
  }

  fun setupThumbnails(url: String) {
    thumbnails.downloadFrames(url)
  }
}

