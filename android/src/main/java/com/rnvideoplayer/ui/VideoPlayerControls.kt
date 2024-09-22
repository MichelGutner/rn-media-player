package com.rnvideoplayer.ui

import android.annotation.SuppressLint
import android.content.Context
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.DefaultTimeBar
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R
import com.rnvideoplayer.fadeIn
import com.rnvideoplayer.fadeOut
import com.rnvideoplayer.ui.controls.BottomControls
import com.rnvideoplayer.utilities.ColorUtils
import com.rnvideoplayer.utilities.layoutParamsCenter

@OptIn(UnstableApi::class)
@SuppressLint("ViewConstructor")
class VideoPlayerControls(val context: ThemedReactContext) : FrameLayout(context) {
  private var overlayView = createOverlayView(context, ColorUtils.blackOpacity50)
  private val mainLayout = createMainFrameLayout(context)
  private var playPauseRoundedBackground = createPlayPauseBackground(context)
  val playPauseButton = createPlayPauseButtonAnimated(context)
  private val drawables = AnimatedDrawables(context)
  private val bottomControls = BottomControls(context)

  val timeBar = bottomControls.timeBar
  val timeCodesDurationView = bottomControls.timeCodesDurationView
  val menuControlLayout = bottomControls.menuControlLayout
  val fullscreenControlLayout = bottomControls.fullscreenControlLayout

  init {
    playPauseRoundedBackground.addView(playPauseButton)

    mainLayout.addView(playPauseRoundedBackground)
    mainLayout.addView(bottomControls)

    overlayView.addView(mainLayout)
    addView(overlayView)
  }

  fun updatePlayPauseIcon(isPlaying: Boolean) {
    if (isPlaying) {
//      replayButton?.visibility = View.INVISIBLE
      playPauseButton.setImageDrawable(drawables.playToPause)
      drawables.playToPause.start()
    } else {
      playPauseButton.setImageDrawable(drawables.pauseToPlay)
      drawables.pauseToPlay.start()
    }
  }

  private fun createOverlayView(context: Context, color: Int): FrameLayout {
    val overlayView = FrameLayout(context)
    overlayView.setBackgroundColor(color)

    overlayView.layoutParams = LayoutParams(
      LayoutParams.MATCH_PARENT,
      LayoutParams.MATCH_PARENT,
    )
    return overlayView
  }

  private fun createPlayPauseBackground(context: Context): FrameLayout {
    val sizeInPx = TypedValue.applyDimension(
      TypedValue.COMPLEX_UNIT_DIP,
      80f,
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
    }
  }

  private fun createMainFrameLayout(context: Context): FrameLayout {
    val mainLayout = FrameLayout(context).apply {
      setPadding(24, 24, 24, 24)
    }
    return mainLayout
  }

  fun toggleOverlay() {
    if (overlayView.visibility == VISIBLE) {
      hideControls()
    } else {
      showControls()
    }
  }

  fun hideControls() {
    animationAppear(bottomControls, 0f, context.resources.displayMetrics.heightPixels.toFloat()) {
      overlayView.fadeOut()
    }
  }

  fun showControls() {
    animationAppear(bottomControls, context.resources.displayMetrics.heightPixels.toFloat(), 0f)
    overlayView.fadeIn()
  }

  private fun animationAppear(
    view: FrameLayout,
    fromValue: Float,
    toValue: Float,
    withEndAction: () -> Unit = {}
  ) {
    view.translationY = fromValue
    bottomControls.animate()
      .translationY(toValue)
      .setDuration(300)
      .setInterpolator(AccelerateDecelerateInterpolator())
      .withEndAction(withEndAction)
      .start()
  }
}
