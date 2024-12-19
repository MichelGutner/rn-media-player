package com.rnvideoplayer.ui

import android.annotation.SuppressLint
import android.content.Context
import android.util.TypedValue
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageButton
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R
import com.rnvideoplayer.fadeIn
import com.rnvideoplayer.fadeOut
import com.rnvideoplayer.mediaplayer.viewModels.components.Title
import com.rnvideoplayer.mediaplayer.viewModels.components.DoubleTapSeek
import com.rnvideoplayer.ui.components.Loading
import com.rnvideoplayer.ui.controls.BottomControls
import com.rnvideoplayer.utilities.ColorUtils
import com.rnvideoplayer.utilities.layoutParamsCenter

@OptIn(UnstableApi::class)
@SuppressLint("ViewConstructor")
class VideoPlayerControls(val context: ThemedReactContext) : FrameLayout(context) {
  var overlayView = createOverlayView(context, ColorUtils.blackOpacity50)
  val mainLayout = createMainFrameLayout(context)

  var playPauseRoundedBackground = createPlayPauseBackground(context)
  val playPauseButton = createPlayPauseButtonAnimated(context)
  val loading by lazy { Loading(context) }

  private val drawables = AnimatedDrawables(context)
  private val bottomControls = BottomControls(context)
  val title = Title(context)
  val leftDoubleTap by lazy { DoubleTapSeek(context, false) }
  val rightDoubleTap by lazy { DoubleTapSeek(context, true) }

  val thumbnails = bottomControls.thumbnail
  val timeBar = bottomControls.timeBar
  val timeCodesDuration = bottomControls.timesCodeDuration
  val timeCodesPosition = bottomControls.timeCodesPosition
  val menuControlLayout = bottomControls.menuControlLayout
  val fullscreenLayout = bottomControls.fullscreenControlLayout
  val fullscreenButton = bottomControls.fullscreenButton

  init {
    mainLayout.addView(title)
    playPauseRoundedBackground.addView(playPauseButton)
    playPauseRoundedBackground.addView(loading)
    mainLayout.addView(playPauseRoundedBackground)
    mainLayout.addView(bottomControls)
    overlayView.addView(mainLayout)

    addView(leftDoubleTap)
    addView(rightDoubleTap)
    addView(overlayView)
  }

  fun updatePlayPauseIcon(isPlaying: Boolean) {
    if (isPlaying) {
      playPauseButton.setImageDrawable(drawables.fromPlayToPause)
      drawables.fromPlayToPause.start()
    } else {
      playPauseButton.setImageDrawable(drawables.fromPauseToPlay)
      drawables.fromPauseToPlay.start()
    }
  }

  fun updateFullscreenIcon(isFullscreen: Boolean) {
    if (isFullscreen) {
      fullscreenButton.setImageDrawable(drawables.fullscreenToExit)
      drawables.fullscreenToExit.start()
    } else {
      fullscreenButton.setImageDrawable(drawables.exitToFullscreen)
      drawables.exitToFullscreen.start()
    }
  }

  private fun createOverlayView(context: Context, color: Int): FrameLayout {
    val overlayView = FrameLayout(context)
    overlayView.setBackgroundColor(color)

    val padding16 = TypedValue.applyDimension(
      TypedValue.COMPLEX_UNIT_DIP,
      16f,
      context.resources.displayMetrics
    ).toInt()
    val padding12 = TypedValue.applyDimension(
      TypedValue.COMPLEX_UNIT_DIP,
      12f,
      context.resources.displayMetrics
    ).toInt()

    overlayView.setPadding(padding16,padding12,padding16,padding16)

    overlayView.layoutParams = LayoutParams(
      LayoutParams.MATCH_PARENT,
      LayoutParams.MATCH_PARENT,
    )
    return overlayView
  }

  private fun createPlayPauseBackground(context: Context): FrameLayout {
    val sizeInPx = TypedValue.applyDimension(
      TypedValue.COMPLEX_UNIT_DIP,
      60f,
      context.resources.displayMetrics
    ).toInt()

    return FrameLayout(context).apply {
      layoutParams = layoutParamsCenter(sizeInPx, sizeInPx)
      setBackgroundResource(R.drawable.rounded_background)
    }
  }

  @SuppressLint("ResourceType")
  fun createPlayPauseButtonAnimated(context: Context): ImageButton {
    return ImageButton(context).apply {
      layoutParams =
        layoutParamsCenter(LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
      val typedValue = TypedValue()
      context.theme.resolveAttribute(
        android.R.attr.selectableItemBackgroundBorderless,
        typedValue,
        true
      )
      setBackgroundResource(typedValue.resourceId)
      setImageResource(R.drawable.animated_play_to_pause)
      visibility = INVISIBLE
    }
  }

  private fun createMainFrameLayout(context: Context): FrameLayout {
    val mainLayout = FrameLayout(context).apply {
      setPadding(24, 24, 24, 24)
    }
    return mainLayout
  }

  fun hideControls() {
    overlayView.fadeOut()
  }

  fun showControls() {
    overlayView.fadeIn()
  }
}
