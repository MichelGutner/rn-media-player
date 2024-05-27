package com.rnvideoplayer.components

import android.annotation.SuppressLint
import android.app.Dialog
import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.ViewGroup
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R

class CustomBottomDialog(
  context: ThemedReactContext,
) : Dialog(context) {

  @SuppressLint("UseCompatLoadingForDrawables")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    val view = LayoutInflater.from(context).inflate(R.layout.custom_dialog, null)
    setContentView(view)
    window?.setBackgroundDrawableResource(android.R.color.transparent)
    // Calculate the maximum width as 80% of the screen width
    val displayMetrics = context.resources.displayMetrics
    val isPortrait = displayMetrics.widthPixels < displayMetrics.heightPixels
    val maxWidth = if (isPortrait) displayMetrics.widthPixels else displayMetrics.heightPixels

    window?.setLayout(maxWidth, ViewGroup.LayoutParams.WRAP_CONTENT)

    window?.setGravity(Gravity.BOTTOM)
    window?.setWindowAnimations(com.google.android.material.R.style.Animation_Design_BottomSheetDialog)
  }

  override fun show() {
    super.show()
  }
}
