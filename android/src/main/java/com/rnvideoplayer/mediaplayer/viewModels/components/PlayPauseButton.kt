package com.rnvideoplayer.mediaplayer.viewModels.components

import android.annotation.SuppressLint
import android.content.Context
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageButton
import androidx.core.view.setPadding
import com.rnvideoplayer.R
import com.rnvideoplayer.utils.layoutParamsWithGravityCenter
import com.rnvideoplayer.utils.AnimatedDrawables

class PlayPauseButton(context: Context) : FrameLayout(context) {
  private val drawables = AnimatedDrawables(context)
  private val playPauseButton = imageButton(context)

  init {
    setupLayout()
    addView(playPauseButton)
  }

  override fun setOnClickListener(l: OnClickListener?) {
    super.setOnClickListener(l)
    playPauseButton.setOnClickListener(l)
  }

  private fun setupLayout() {
    layoutParams = LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
      gravity = Gravity.CENTER
    }
    setPadding(12)
    setBackgroundResource(R.drawable.rounded_background)
  }

  @SuppressLint("ResourceType")
  private fun imageButton(context: Context): ImageButton {
    return ImageButton(context).apply {
      layoutParams =
        layoutParamsWithGravityCenter(LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
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

  fun updateIcon(isPlaying: Boolean) {
    if (isPlaying && playPauseButton.drawable == drawables.fromPauseToPlay) {
      playPauseButton.setImageDrawable(drawables.fromPlayToPause)
      drawables.fromPlayToPause.start()
    } else if (!isPlaying && playPauseButton.drawable == drawables.fromPlayToPause) {
      playPauseButton.setImageDrawable(drawables.fromPauseToPlay)
      drawables.fromPauseToPlay.start()
    }
  }
}
