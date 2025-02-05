package com.rnvideoplayer.mediaplayer.viewModels

import android.annotation.SuppressLint
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.core.view.isVisible
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.TimeBar
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.extensions.fadeIn
import com.rnvideoplayer.extensions.fadeOut
import com.rnvideoplayer.extensions.withTranslationAnimation
import com.rnvideoplayer.mediaplayer.models.MediaPlayerSource
import com.rnvideoplayer.mediaplayer.viewModels.components.DoubleTapSeek
import com.rnvideoplayer.mediaplayer.viewModels.components.FullscreenButton
import com.rnvideoplayer.mediaplayer.viewModels.components.Loading
import com.rnvideoplayer.mediaplayer.viewModels.components.MenuButton
import com.rnvideoplayer.mediaplayer.viewModels.components.PlayPauseButton
import com.rnvideoplayer.mediaplayer.viewModels.components.PlayerLayer
import com.rnvideoplayer.mediaplayer.viewModels.components.SeekBar
import com.rnvideoplayer.mediaplayer.viewModels.components.Thumbnail
import com.rnvideoplayer.mediaplayer.viewModels.components.TimeCodes
import com.rnvideoplayer.mediaplayer.viewModels.components.VideoTitle
import com.rnvideoplayer.utils.Utils
import java.util.concurrent.TimeUnit
import kotlin.math.roundToInt

enum class ControlType {
  PLAY_PAUSE,
  FULLSCREEN,
  OPTIONS_MENU,
  SEEK_GESTURE_FORWARD,
  SEEK_GESTURE_BACKWARD,
  PINCH_ZOOM,
  TOUCH_VIEW
}
interface MediaPlayerControlsViewListener {
  fun control(type: ControlType, event: Any? = null)
}

@SuppressLint("ViewConstructor")
@UnstableApi
class MediaPlayerControls(private val context: ThemedReactContext) : FrameLayout(context) {
  private var listener: MediaPlayerControlsViewListener? = null

  fun setListener(listener: MediaPlayerControlsViewListener) {
    this.listener = listener
  }
  private val playerLayer = PlayerLayer(context)
  private val overlay = createOverlayView()

  private val playPauseControl = PlayPauseButton(context)

  private val videoTitle = VideoTitle(context)

//  private val castButton = CastButton(context)

  private val thumbnail by lazy { Thumbnail(context) }

  private val fullscreenButton = FullscreenButton(context)

  private val optionsMenuButton = MenuButton(context)

  private val seekBar = SeekBar(context)

  private val timeCodes = TimeCodes(context)

  private val leftSeekGestureView by lazy { DoubleTapSeek(context, false) }

  private val rightSeekGestureView by lazy { DoubleTapSeek(context, true) }

  private val loading by lazy { Loading(context) }

  private val topContainer = createHorizontalLinearLayout().apply {
    gravity = Gravity.TOP
    setPadding(12, 0, 12, 0)
  }
  private val thumbnailContainer = createHorizontalLinearLayout()
  private val bottomContainer = createSimpleFrameLayout()

  private val bottomInteractionControlsContainer = createHorizontalLinearLayout().apply {
    gravity = Gravity.BOTTOM or Gravity.END
    setPadding(0, 0, 12, 8)
  }
  private val thumbnailAndControlsContainer = FrameLayout(context).apply {
    layoutParams = ViewGroup.LayoutParams(
      ViewGroup.LayoutParams.MATCH_PARENT,
      ViewGroup.LayoutParams.MATCH_PARENT
    )
  }
  private val seekBarContainer = createLinearVerticalLayout()
  private val container = FrameLayout(context).apply {
    layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
  }

  private var clickCount = 0
  private var lastClickTime = 0L
  private var isPinchGesture: Boolean = false

  data class ScrubberPosition(
    val startPositionSeconds: Int,
    val startPositionPercent: Int,
    val endPositionSeconds: Int,
    val endPositionPercent: Int
  )

  private val mainLayout = FrameLayout(context).apply {
    layoutParams = LayoutParams(
      LayoutParams.MATCH_PARENT,
      LayoutParams.MATCH_PARENT
    )
  }

  var startScrubberPositionSeconds = 0
  var startScrubberPositionPercent = 0

  init {
    topContainer.addView(videoTitle)
    topContainer.addView(View(context).apply {
      layoutParams = LinearLayout.LayoutParams(0, 0).apply {
        weight = 1f
      }
    })
//    topContainer.addView(castButton)
    topContainer.addView(optionsMenuButton)

//    bottomInteractionControlsContainer.addView(optionsMenuButton)
    bottomInteractionControlsContainer.addView(fullscreenButton)


    seekBarContainer.addView(seekBar)
    seekBarContainer.addView(timeCodes)

    thumbnailContainer.addView(thumbnail)
    thumbnailAndControlsContainer.addView(bottomInteractionControlsContainer)
    thumbnailAndControlsContainer.addView(thumbnailContainer)

    bottomContainer.addView(thumbnailAndControlsContainer)
    bottomContainer.addView(seekBarContainer)


    overlay.addView(topContainer)
    overlay.addView(playPauseControl)
    overlay.addView(bottomContainer)

    container.addView(leftSeekGestureView)
    container.addView(rightSeekGestureView)

    container.addView(overlay)
    container.addView(loading)

    mainLayout.addView(playerLayer.frame)
    mainLayout.addView(container)

    addView(mainLayout)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    createListeners()
  }

  @SuppressLint("ClickableViewAccessibility")
  override fun onTouchEvent(event: MotionEvent): Boolean {
    when (event.actionMasked) {
      MotionEvent.ACTION_DOWN -> {
        val currentTime = System.currentTimeMillis()

        if (event.pointerCount == 1) {
          isPinchGesture = false
        }

        if (currentTime - lastClickTime < 300) {
          clickCount++
        } else {
          clickCount = 1
        }
        lastClickTime = currentTime
      }

      MotionEvent.ACTION_POINTER_DOWN -> {
        if (event.pointerCount > 1) {
          isPinchGesture = true
        }
      }

      MotionEvent.ACTION_MOVE -> {
        if (event.pointerCount > 1) {
          playerLayer.pinchGesture.onTouchEvent(event)
        }
      }

      MotionEvent.ACTION_UP -> {
        if (event.pointerCount == 1 && !isPinchGesture && clickCount < 2) {
          listener?.control(ControlType.TOUCH_VIEW)
          toggleOverlayVisibility()
        } else {
          val roundedScaleX = (playerLayer.frame.scaleX * 100).roundToInt() / 100f
          val currentZoom = if (roundedScaleX > 1) "resizeAspectFill" else "resizeAspect"
          listener?.control(ControlType.PINCH_ZOOM, currentZoom)
        }

        if (clickCount >= 2) {
          if (event.x < width / 2) {
            shouldShowLeftGestureSeek()
          } else {
            shouldShowRightGestureSeek()
          }
        }
      }

      MotionEvent.ACTION_POINTER_UP -> {
        if (event.pointerCount <= 1) {
          isPinchGesture = false
        }
      }
    }
    return true
  }

  private fun createListeners() {
    playPauseControl.setOnClickListener {
      listener?.control(ControlType.PLAY_PAUSE)
    }
    fullscreenButton.setOnClickListener {
      listener?.control(ControlType.FULLSCREEN)
    }
    optionsMenuButton.setOnClickListener { anchorView ->
      listener?.control(ControlType.OPTIONS_MENU, anchorView)
    }
    leftSeekGestureView.onTapListener { value ->
      listener?.control(ControlType.SEEK_GESTURE_BACKWARD, value)
    }
    rightSeekGestureView.onTapListener { value ->
      listener?.control(ControlType.SEEK_GESTURE_FORWARD, value)
    }
  }

  private fun createOverlayView(): FrameLayout {
    val paddingInPx = dpToPx(14f)

    val gradientBackground = GradientDrawable(
      GradientDrawable.Orientation.TOP_BOTTOM,
      intArrayOf(Utils.COLOR_BLACK_ALPHA_05, Utils.COLOR_BLACK_ALPHA_02, Utils.COLOR_BLACK_ALPHA_05)
    )

    return FrameLayout(context).apply {
      background = gradientBackground
      layoutParams = LayoutParams(
        LayoutParams.MATCH_PARENT,
        LayoutParams.MATCH_PARENT
      )
      setPadding(paddingInPx, paddingInPx, paddingInPx, paddingInPx)
    }
  }

  private fun createHorizontalLinearLayout(): LinearLayout {
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

  private fun createLinearVerticalLayout(): LinearLayout {
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

  private fun createSimpleFrameLayout(): LinearLayout {
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

  private fun shouldShowLeftGestureSeek() {
    leftSeekGestureView.show()
    leftSeekGestureView.hide()
    hideOverlay(false)
  }

  private fun shouldShowRightGestureSeek() {
    rightSeekGestureView.show()
    rightSeekGestureView.hide()
    hideOverlay(false)
  }

  private fun dpToPx(dp: Float): Int {
    return TypedValue.applyDimension(
      TypedValue.COMPLEX_UNIT_DIP,
      dp,
      context.resources.displayMetrics
    ).toInt()
  }

  fun seekBarListener(
    exoPlayer: MediaPlayerSource,
    getIsSeeking: (Boolean) -> Unit,
    onSeek: (lastPosition: Boolean, ScrubberPosition) -> Unit
  ) {
    this@MediaPlayerControls.seekBar.onScrubListener(object : TimeBar.OnScrubListener {
      override fun onScrubStart(seekBar: TimeBar, position: Long) {
        getIsSeeking(true)
        val totalDurationSeconds =
          TimeUnit.MILLISECONDS.toSeconds(exoPlayer.duration).toInt()
        startScrubberPositionSeconds = TimeUnit.MILLISECONDS.toSeconds(position).toInt()

        startScrubberPositionPercent = if (totalDurationSeconds > 0) {
          (startScrubberPositionSeconds * 100) / totalDurationSeconds
        } else { 0 }
        shouldShowThumbnail()
        hideInteractionControls()
      }

      override fun onScrubMove(seekBar: TimeBar, position: Long) {
        val duration = TimeUnit.MILLISECONDS.toSeconds(exoPlayer.duration)
        val seconds = TimeUnit.MILLISECONDS.toSeconds(position)
        shouldUpdateThumbnailPosition(position)
        shouldUpdateThumbnailTranslateX(
          seconds.toDouble(),
          duration.toDouble(),
        )
      }

      override fun onScrubStop(seekBar: TimeBar, position: Long, canceled: Boolean) {
        getIsSeeking(false)
        val endScrubberPositionSeconds = TimeUnit.MILLISECONDS.toSeconds(position).toInt()
        val totalDurationSeconds =
          TimeUnit.MILLISECONDS.toSeconds(exoPlayer.duration).toInt()

        val endScrubberPositionPercent = if (totalDurationSeconds > 0) {
          (endScrubberPositionSeconds * 100) / totalDurationSeconds
        } else {
          0
        }

        val scrubberPosition  = ScrubberPosition(
          startScrubberPositionPercent,
          startScrubberPositionSeconds,
          endScrubberPositionPercent,
          endScrubberPositionSeconds
        )
        shouldHideThumbnail()
        showInteractionControls()

        val positionTolerance = -1
        val isLastPosition = endScrubberPositionSeconds >= totalDurationSeconds - positionTolerance
        onSeek(isLastPosition, scrubberPosition)
        if (!canceled) {
          exoPlayer.seekTo(position)
        }
      }
    })
  }

  private fun toggleOverlayVisibility() {
    if (overlay.isVisible) {
      hideOverlay()
      seekBarContainer.withTranslationAnimation(20f)
      topContainer.withTranslationAnimation(-20f)
    } else {
      showOverlay()
      seekBarContainer.withTranslationAnimation()
      topContainer.withTranslationAnimation()
    }
  }

  fun hideOverlay(animated: Boolean? = true) {
    if (animated!!) {
      overlay.fadeOut()
    } else {
      overlay.visibility = INVISIBLE
    }
  }

  private fun showOverlay(animated: Boolean? = true) {
    if (animated!!) {
      overlay.fadeIn()
    } else {
      overlay.visibility = VISIBLE
    }
  }

  fun updateAnimatedPlayPauseIcon(isPlaying: Boolean) {
    playPauseControl.updateIcon(isPlaying)
  }

  fun updateFullscreenIcon(isFullscreen: Boolean) {
    fullscreenButton.updateFullscreenIcon(isFullscreen)
  }

  fun setSurfaceMediaPlayerView(surfaceView: SurfaceView) {
    playerLayer.frame.addView(surfaceView)
  }

  fun hideInteractionControls() {
    fullscreenButton.fadeOut()
    optionsMenuButton.fadeOut()
    playPauseControl.fadeOut()
//    castButton.fadeOut()
  }

  fun showInteractionControls() {
    fullscreenButton.fadeIn()
    playPauseControl.fadeIn()
    optionsMenuButton.fadeIn()
//    castButton.fadeIn()
  }

  fun removeLoading() {
    postDelayed({
      loading.fadeOut {
        container.removeView(loading)
        container.requestLayout()
      }
    }, 300)
  }

  fun modifyConfigLeftGestureSeek(value: Int, suffix: String) {
    leftSeekGestureView.tapValue = value
    leftSeekGestureView.suffixLabel = suffix
  }

  fun modifyConfigRightGestureSeek(value: Int, suffix: String) {
    rightSeekGestureView.tapValue = value
    rightSeekGestureView.suffixLabel = suffix
  }

  fun shouldShowThumbnail() {
    thumbnail.show()
  }

  fun shouldHideThumbnail() {
    thumbnail.hide()
  }

  fun shouldUpdateThumbnailPosition(position: Long) {
    thumbnail.updatePosition(position)
  }

  fun shouldUpdateThumbnailTranslateX(seconds: Double, duration: Double) {
    thumbnail.onTranslateX(seconds, duration, seekBar.width)
  }

  fun setThumbnailPositionX(value: Float) {
    thumbnail.positionX = value
  }

  fun shouldExecuteDownloadThumbnailFrames(url: String) {
    thumbnail.downloadFrames(url)
  }

  fun setSeekBarDuration(duration: Long) {
    seekBar.setDuration(duration)
    timeCodes.setDuration(duration)
  }

  fun setSeekBarProgress(position: Long, bufferProgress: Long) {
    seekBar.setPosition(position, bufferProgress)
    timeCodes.setPosition(position)
  }

  fun setVideoTitle(title: String) {
    videoTitle.setTitle(title)
  }
}
