package com.rnvideoplayer.mediaplayer.viewModels.components

import android.annotation.SuppressLint
import android.content.Context
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageButton
import com.rnvideoplayer.R
import com.rnvideoplayer.ui.AnimatedDrawables
import com.rnvideoplayer.utilities.layoutParamsCenter

class PlayPauseButton(context: Context) : FrameLayout(context) {
  private val drawables = AnimatedDrawables(context)
  private var size: Int = 60
  private val playPauseButton = setupButton(context)

  init {
    setupLayout()
    addView(playPauseButton)
  }

  override fun setOnClickListener(l: OnClickListener?) {
    super.setOnClickListener(l)
    playPauseButton.setOnClickListener(l)
  }

  private fun setupLayout() {
    layoutParams = LayoutParams(size, size).apply {
      gravity = Gravity.CENTER
    }
    setBackgroundResource(R.drawable.rounded_background)
  }

  @SuppressLint("ResourceType")
  private fun setupButton(context: Context): ImageButton {
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
      setImageDrawable(drawables.fromPauseToPlay)
    }
  }

  fun setSize(value: Int) {
    size = value
    layoutParams = LayoutParams(size, size).apply {
      gravity = Gravity.CENTER
    }
  }

  fun updatePlayPauseIcon(isPlaying: Boolean) {
    if (isPlaying && playPauseButton.drawable == drawables.fromPauseToPlay) {
      playPauseButton.setImageDrawable(drawables.fromPlayToPause)
      drawables.fromPlayToPause.start()
    } else if (!isPlaying && playPauseButton.drawable == drawables.fromPlayToPause) {
      playPauseButton.setImageDrawable(drawables.fromPauseToPlay)
      drawables.fromPauseToPlay.start()
    }
  }
}
