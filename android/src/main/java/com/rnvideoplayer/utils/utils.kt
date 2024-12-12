package com.rnvideoplayer.utils

import android.view.View


fun scaleView(isForward: Boolean, view: View) {
  val centerButton = 40f
  if (isForward) {
    view.pivotX = 0f
    view.translationX = (view.width.toFloat() / 2f + centerButton)
  } else {
    view.pivotX = view.width.toFloat()
    view.translationX = -(view.width.toFloat() / 2f + centerButton)
  }
  view.pivotY = view.height / 2f
  view.animate().scaleX(1f).scaleY(1.2f).setDuration(200).start()
  view.requestLayout()
}

