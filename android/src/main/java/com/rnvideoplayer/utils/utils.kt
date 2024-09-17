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

fun View.fadeOut(duration: Long = 500) {
  this.post {
    this.animate()
      .alpha(0f)
      .setDuration(duration)
      .setListener(object : AnimatorListenerAdapter() {
        override fun onAnimationEnd(animation: Animator) {
          this@fadeOut.visibility = View.INVISIBLE
        }
      })
  }
}


fun scaleView(isForward: Boolean, view: View) {
  val scale = 1f
  if (isForward) {
    view.pivotX = 0f
    view.translationX = (view.width.toFloat() / 2f + 80)
  } else {
  view.pivotX = view.width.toFloat()
  view.translationX = -(view.width.toFloat() / 2f + 80)

  }
  view.pivotY = view.height / 2f
  view.animate().scaleX(scale).scaleY(scale).setDuration(200).start()
  view.requestLayout()
}

