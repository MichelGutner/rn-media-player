package com.rnvideoplayer.ui

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.drawable.AnimatedVectorDrawable
import com.rnvideoplayer.R

open class AnimatedDrawables(val context: Context) {
  val playToPause = createAnimatedDrawable(R.drawable.animated_play_to_pause)
  val pauseToPlay = createAnimatedDrawable(R.drawable.animated_pause_to_play)

  @SuppressLint("UseCompatLoadingForDrawables")
  private fun createAnimatedDrawable(drawableResId: Int): AnimatedVectorDrawable {
    return context.getDrawable(drawableResId) as AnimatedVectorDrawable
  }
}
