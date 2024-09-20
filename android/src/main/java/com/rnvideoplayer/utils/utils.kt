package com.rnvideoplayer.utils

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.view.View

fun View.fadeIn(duration: Long = 500) {
  this.post {
    this.visibility = View.VISIBLE
    this.alpha = 0f
    this.animate()
      .alpha(1f)
      .setDuration(duration)
      .setListener(null)
  }
}

fun View.fadeOut(duration: Long = 500, completion: (() -> Unit)? = null) {
  this.post {
    this.animate()
      .alpha(0f)
      .setDuration(duration)
      .setListener(object : AnimatorListenerAdapter() {
        override fun onAnimationEnd(animation: Animator) {
          this@fadeOut.visibility = View.INVISIBLE
          completion.also {
            it?.invoke()
          }
        }
      })
  }
}


fun scaleView(isForward: Boolean, view: View) {
  val playPauseButtonSize = 80f
  if (isForward) {
    view.pivotX = 0f
    view.translationX = (view.width.toFloat() / 2f + playPauseButtonSize)
  } else {
  view.pivotX = view.width.toFloat()
  view.translationX = -(view.width.toFloat() / 2f + playPauseButtonSize)

  }
  view.pivotY = view.height / 2f
  view.animate().scaleX(1f).scaleY(1f).setDuration(200).start()
  view.requestLayout()
}

