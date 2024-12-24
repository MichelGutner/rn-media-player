package com.rnvideoplayer.mediaplayer.viewModels

import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.core.view.isVisible
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.util.Log
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.TimeBar
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.cast.CastPlayerButton
import com.rnvideoplayer.extensions.fadeIn
import com.rnvideoplayer.extensions.fadeOut
import com.rnvideoplayer.extensions.withTranslationAnimation
import com.rnvideoplayer.mediaplayer.models.ReactEventsAdapter
import com.rnvideoplayer.mediaplayer.models.MediaPlayerAdapter
import com.rnvideoplayer.interfaces.IMediaPlayerControls
import com.rnvideoplayer.mediaplayer.models.ReactConfigAdapter
import com.rnvideoplayer.mediaplayer.models.ReactEventsName
import com.rnvideoplayer.mediaplayer.viewModels.components.FullscreenButton
import com.rnvideoplayer.mediaplayer.viewModels.components.PlayPauseButton
import com.rnvideoplayer.mediaplayer.viewModels.components.SeekBar
import com.rnvideoplayer.mediaplayer.viewModels.components.Title
import com.rnvideoplayer.mediaplayer.viewModels.components.DoubleTapSeek
import com.rnvideoplayer.mediaplayer.viewModels.components.MenuButton
import com.rnvideoplayer.mediaplayer.viewModels.components.TimeCodes
import com.rnvideoplayer.mediaplayer.viewModels.components.Loading
import com.rnvideoplayer.mediaplayer.viewModels.components.PopUpMenu
import com.rnvideoplayer.mediaplayer.viewModels.components.Thumbnail
import com.rnvideoplayer.utils.TaskScheduler
import com.rnvideoplayer.utils.TimeUnitFormat
import com.rnvideoplayer.utils.Utils
import java.util.concurrent.TimeUnit


@UnstableApi
abstract class MediaPlayerControls(context: ThemedReactContext) : FrameLayout(context), IMediaPlayerControls {
  val controlsContainer = FrameLayout(context).apply {
    layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
  }

  private var taskScheduler = TaskScheduler()
  protected var reactApplicationEvent: ReactEventsAdapter? = null
  protected var reactConfigAdapter: ReactConfigAdapter? = null
  private var timeUnitHandler = TimeUnitFormat()
  private val handler = Handler(Looper.getMainLooper())
  private val mediaPlayer = MediaPlayerAdapter(context)
  private var castPlayerButton = CastPlayerButton(context, mediaPlayer.instanceExoPlayer)

  private val overlay = overlayView()
  private val loading by lazy { Loading(context) }
  private val playPauseButton = PlayPauseButton(context)
  private val fullscreenButton = FullscreenButton(context)
  private val optionsMenuButton = MenuButton(context)

  private val seekBar = SeekBar(context)
  private val seekBarTimeCodes = TimeCodes(context)
  private val seekBarContainer = customLinearVerticalLayout()

  private val title = Title(context)

  private val thumbnail by lazy { Thumbnail(context) }
  private val thumbnailContainer = customLinearHorizontalLayout()

  private val bottomControlBar = customLinearHorizontalLayout().apply {
    gravity = Gravity.BOTTOM or Gravity.END
    setPadding(0, 0, 12, 8)
  }

  private val thumbnailAndControlsContainer = FrameLayout(context).apply {
    layoutParams = ViewGroup.LayoutParams(
      ViewGroup.LayoutParams.MATCH_PARENT,
      ViewGroup.LayoutParams.MATCH_PARENT
    )
  }

  private val mediaControlsContainer = customFrameLayout()

  private var startScrubberPositionSeconds = 0
  private var startScrubberPositionPercent = 0

  private var isFullscreen = false
  private var isFinished = false
  private var enterFullScreenWhenPlaybackBegins = false

  val surfaceView = mediaPlayer.surfaceView
  val leftSeekGestureView by lazy { DoubleTapSeek(context, false) }
  val rightSeekGestureView by lazy { DoubleTapSeek(context, true) }

  init {
    setupReactConfigs()
    initializerPlayerCallbacks()
    initializerPlayerComponents()
    seekBarListener()
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    val enterFullscreenWhenPlaybackBeginsConfig = reactConfigAdapter?.get(ReactConfigAdapter.Key.ENTERS_FULL_SCREEN_WHEN_PLAYBACK_BEGINS) ?: false
    enterFullScreenWhenPlaybackBegins = enterFullscreenWhenPlaybackBeginsConfig as Boolean

    postDelayed({
      timeoutControls()
      if (enterFullscreenWhenPlaybackBeginsConfig) {
        mutateFullScreenState(enterFullScreenWhenPlaybackBegins)
      }
    }, 400)
  }

  open fun addEvents(reactEventsAdapter: ReactEventsAdapter?) {
    reactApplicationEvent = reactEventsAdapter
  }

  open fun addReactConfigs(config: ReactConfigAdapter) {
    this.reactConfigAdapter = config
  }

  private fun initializerPlayerComponents() {
    playPauseButton.setOnClickListener {
      onTogglePlayPause()
    }
    fullscreenButton.setOnClickListener {
      toggleFullscreen()
    }
    optionsMenuButton.setOnClickListener { anchorView ->
      showPopUp(anchorView)
    }

    leftSeekGestureView.onTapListener { value ->
      mediaPlayer.seekToRelativePosition(-((value * 1000).toLong()))
    }

    rightSeekGestureView.onTapListener { value ->
      mediaPlayer.seekToRelativePosition(((value * 1000).toLong()))
    }

    bottomControlBar.addView(optionsMenuButton)
    bottomControlBar.addView(fullscreenButton)

    thumbnailContainer.addView(thumbnail)

    thumbnailAndControlsContainer.addView(bottomControlBar)
    thumbnailAndControlsContainer.addView(thumbnailContainer)

    seekBarContainer.addView(seekBar)
    seekBarContainer.addView(seekBarTimeCodes)

    mediaControlsContainer.addView(thumbnailAndControlsContainer)
    mediaControlsContainer.addView(seekBarContainer)

    overlay.addView(title)
//    overlay.addView(castPlayerButton)
    overlay.addView(playPauseButton)
    overlay.addView(mediaControlsContainer)

    controlsContainer.addView(leftSeekGestureView)
    controlsContainer.addView(rightSeekGestureView)

    controlsContainer.addView(overlay)
    controlsContainer.addView(loading)
  }

  private fun onTogglePlayPause() {
    mediaPlayer.onMediaTogglePlayPause()
    timeoutControls()
  }

  private fun initializerPlayerCallbacks() {
    mediaPlayer.addCallback(object : MediaPlayerAdapter.Callback {
      override fun onMediaLoaded(duration: Long) {
        seekBar.build(duration)
        seekBarTimeCodes.updateDuration(duration)
        reactApplicationEvent?.send(
          ReactEventsName.MEDIA_READY,
          this@MediaPlayerControls,
          Arguments.createMap().apply {
            putDouble("duration", timeUnitHandler.toSecondsDouble(duration))
            putBoolean("loaded", true)
          })
        postDelayed({
          loading.fadeOut {
            controlsContainer.removeView(loading)
            controlsContainer.requestLayout()
          }
        }, 400)
      }

      override fun onPlaybackStateChanged(isPlaying: Boolean) {
        playPauseButton.updatePlayPauseIcon(isPlaying)
        reactApplicationEvent?.send(
          ReactEventsName.MEDIA_PLAY_PAUSE,
          this@MediaPlayerControls,
          Arguments.createMap().apply {
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
            putString(
              "userInfo", mapOf(
                "NSLocalizedDescriptionKey" to error?.message,
                "NSLocalizedFailureReasonErrorKey" to "Failed to play the video.",
                "NSLocalizedRecoverySuggestionErrorKey" to "Please check the video source or try again later."
              ).toString()
            )
          })
      }

      override fun onMediaBuffering(currentProgress: Long, bufferedProgress: Long) {
        seekBar.update(currentProgress, bufferedProgress)
        seekBarTimeCodes.updatePosition(currentProgress)
        reactApplicationEvent?.send(
          ReactEventsName.MEDIA_BUFFERING,
          this@MediaPlayerControls,
          Arguments.createMap().apply {
            putDouble("progress", TimeUnit.MILLISECONDS.toSeconds(currentProgress).toDouble())
            putDouble("totalBuffered", TimeUnit.MILLISECONDS.toSeconds(bufferedProgress).toDouble())
          })
      }

      override fun onMediaBufferCompleted() {
        reactApplicationEvent?.send(
          ReactEventsName.MEDIA_BUFFER_COMPLETED,
          this@MediaPlayerControls,
          Arguments.createMap().apply {
            putBoolean("completed", true)
          })
      }

      override fun getMediaMetadata(mediaMetadata: MediaMetadata) {
        title.setTitle(mediaMetadata.title.toString())
      }

      override fun onPlaybackStateEndedInvoked() {
        thumbnail.translationXThumbnailView = 0f
      }

      override fun onMediaEnded() {
        reactApplicationEvent?.send(
          ReactEventsName.MEDIA_COMPLETED,
          this@MediaPlayerControls,
          Arguments.createMap().apply {
            putBoolean("completed", true)
          })
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
        thumbnail.show()
        hideControls()
      }

      override fun onScrubMove(seekBar: TimeBar, position: Long) {
        val duration = TimeUnit.MILLISECONDS.toSeconds(mediaPlayer.duration)
        val seconds = TimeUnit.MILLISECONDS.toSeconds(position)
        thumbnail.updatePosition(position)
        thumbnail.onTranslate(
          seconds.toDouble(),
          duration.toDouble(),
          this@MediaPlayerControls.seekBar.width
        )
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

        reactApplicationEvent?.send(
          ReactEventsName.MEDIA_SEEK_BAR,
          this@MediaPlayerControls,
          Arguments.createMap().apply {
            putMap("start", startMap)
            putMap("end", endMap)
          })

        timeoutControls()
        thumbnail.hide()
        showControls()

        this@MediaPlayerControls.seekBar.animate().scaleX(1.0f).scaleY(1.0f).setDuration(500)
          .start()
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
        val doubleTapSeekValue = reactConfigAdapter?.get(ReactConfigAdapter.Key.DOUBLE_TAP_TO_SEEK_VALUE) as Int
        val doubleTapSuffix = reactConfigAdapter?.get(ReactConfigAdapter.Key.DOUBLE_TAP_TO_SEEK_SUFFIX_LABEL)

        leftSeekGestureView.tapValue = doubleTapSeekValue
        leftSeekGestureView.suffixLabel = doubleTapSuffix.toString()

        rightSeekGestureView.tapValue = doubleTapSeekValue
        rightSeekGestureView.suffixLabel = doubleTapSuffix.toString()

        viewTreeObserver.removeOnGlobalLayoutListener(this)
      }
    })
  }

  private fun toggleFullscreen() {
    overlay.visibility = INVISIBLE
    timeoutControls()
    mutateFullScreenState(!isFullscreen)
    reactApplicationEvent?.send(
      ReactEventsName.FULL_SCREEN_STATE_CHANGED,
      this@MediaPlayerControls,
      Arguments.createMap().apply {
        putBoolean("isFullscreen", isFullscreen)
      }
    )
  }

  private fun mutateFullScreenState(state: Boolean) {
    onFullscreenMode(state)
    fullscreenButton.updateFullscreenIcon(state)
    isFullscreen = state
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
      setPadding(padding, padding, padding, padding)
    }
  }

  private fun dpToPx(dp: Float): Int {
    return TypedValue.applyDimension(
      TypedValue.COMPLEX_UNIT_DIP,
      dp,
      context.resources.displayMetrics
    ).toInt()
  }

  private fun customFrameLayout(): LinearLayout {
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

  private fun customLinearVerticalLayout(): LinearLayout {
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

  private fun customLinearHorizontalLayout(): LinearLayout {
    return LinearLayout(context).apply {
      layoutParams = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.MATCH_PARENT,
      ).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
      }
    }
  }

  private fun hideControls() {
    fullscreenButton.fadeOut()
    playPauseButton.fadeOut()
    optionsMenuButton.fadeOut()
  }

  private fun showControls() {
    fullscreenButton.fadeIn()
    playPauseButton.fadeIn()
    optionsMenuButton.fadeIn()
  }

  private fun showPopUp(view: View) {
    val popupMenu by lazy {
      PopUpMenu(context, view) { title, value ->
        reactApplicationEvent?.send(
          ReactEventsName.MENU_ITEM_SELECTED,
          this,
          Arguments.createMap().apply {
            putString("name", title)
            putString("value", value.toString())
          })
      }
    }
    popupMenu.show()
  }

  private fun timeoutControls() {
    taskScheduler.cancelTask()

    taskScheduler.createTask(3500) {
      if (mediaPlayer.isPlaying && !seekBar.isSeeking) {
        overlay.fadeOut()
      }
    }
  }

  fun toggleOverlayVisibility() {
    timeoutControls()
    if (overlay.isVisible) {
      overlay.fadeOut()
      seekBarContainer.withTranslationAnimation(20f)
      title.withTranslationAnimation(-20f)
    } else {
      overlay.fadeIn()
      seekBarContainer.withTranslationAnimation()
      title.withTranslationAnimation()
    }
  }

  fun mediaPlayerRelease() {
    mediaPlayer.onMediaRelease()
    taskScheduler.cancelTask()
  }

  fun setupMediaPlayer(url: String, startTime: Long? = 0, metadata: MediaMetadata? = null) {
    mediaPlayer.onMediaBuild(url, startTime, metadata)
  }

  fun onAutoPlay(autoPlayer: Boolean) {
    mediaPlayer.onMediaAutoPlay(autoPlayer)
  }

  fun startDownloadThumbnailFrames(url: String) {
    thumbnail.downloadFrames(url)
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

