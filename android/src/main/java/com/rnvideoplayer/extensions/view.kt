package com.rnvideoplayer.extensions

import android.view.View

fun View.animatedScale(isForward: Boolean) {
  if (isForward) {
    this.pivotX = 0f
    this.translationX = (this.width.toFloat() / 2f + 40)
  } else {
    this.pivotX = this.width.toFloat()
    this.translationX = -(this.width.toFloat() / 2f + 40)
  }
  this.pivotY = this.height / 2f
  this.animate().scaleX(1.2f).scaleY(1.2f).setDuration(200).start()
  this.requestLayout()
}

fun View.fadeIn(duration: Long = 300, completion: () -> Unit = {}) {
  this.post {
    this.visibility = View.VISIBLE
    this.alpha = 0f
    this.animate()
      .alpha(1f)
      .withEndAction { completion.invoke() }
      .setDuration(duration)
      .setListener(null)
  }
}

fun View.fadeOut(duration: Long = 300, completion: (() -> Unit)? = null) {
  post {
    animate()
      .alpha(0f)
      .setDuration(duration)
      .withEndAction {
        visibility = View.INVISIBLE
        completion?.invoke()
      }
  }
}

fun View.withTranslationAnimation(translationY: Float? = 0f, duration: Long? = 300) {
  this.post {
    animate()
      .translationY(translationY!!)
      .setDuration(duration!!)
      .start()
  }
}
