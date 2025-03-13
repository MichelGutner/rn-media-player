package com.rnvideoplayer.mediaplayer.models

import android.content.Context
import android.media.ExifInterface
import android.view.OrientationEventListener

interface HardwareSensorOrientationListener {
  fun changedOrientation(currentOrientation: Int, lastOrientation: Int)
}

class HardwareSensorOrientation(context: Context) : OrientationEventListener(context) {
  private var listener: HardwareSensorOrientationListener? = null
  private var lastOrientation: MutableList<Int> = mutableListOf(ExifInterface.ORIENTATION_ROTATE_90)

  fun setListener(listener: HardwareSensorOrientationListener) {
    this.listener = listener
  }

  init {
    if (canDetectOrientation()) {
      enable()
    }
  }

  override fun onOrientationChanged(orientation: Int) {
    val currentOrientation = calculateSensorOrientationByDegrees(orientation)
    if (currentOrientation != lastOrientation.last()) {
      val previousOrientation = lastOrientation.last()
      lastOrientation.removeAt(0)
      lastOrientation.add(currentOrientation)
      listener?.changedOrientation(currentOrientation, previousOrientation)
    }
  }

  private fun calculateSensorOrientationByDegrees(orientation: Int): Int {
    return when (orientation) {
      in 0..60 -> ExifInterface.ORIENTATION_ROTATE_90 // PORTRAIT
      in 60..120 -> ExifInterface.ORIENTATION_ROTATE_180 // LANDSCAPE_REVERSE
      in 240..320 -> ExifInterface.ORIENTATION_NORMAL // LANDSCAPE
      in 330..359 -> ExifInterface.ORIENTATION_ROTATE_90 // PORTRAIT
      else -> lastOrientation.last()
    }
  }
}
