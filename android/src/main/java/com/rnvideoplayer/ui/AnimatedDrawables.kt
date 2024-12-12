package com.rnvideoplayer.ui

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.drawable.AnimatedVectorDrawable
import com.rnvideoplayer.R

open class AnimatedDrawables(val context: Context) {
  val fromPlayToPause = createAnimatedDrawable(R.drawable.animated_play_to_pause)
  val fromPauseToPlay = createAnimatedDrawable(R.drawable.animated_pause_to_play)

  val fullscreenToExit = createAnimatedDrawable(R.drawable.animated_full_to_exit)
  val exitToFullscreen = createAnimatedDrawable(R.drawable.animated_exit_to_full)

  @SuppressLint("UseCompatLoadingForDrawables")
  private fun createAnimatedDrawable(drawableResId: Int): AnimatedVectorDrawable {
    return context.getDrawable(drawableResId) as AnimatedVectorDrawable
  }
}
