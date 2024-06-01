package com.rnvideoplayer.components

import android.annotation.SuppressLint
import android.app.Dialog
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import com.facebook.react.uimanager.ThemedReactContext

class CustomBottomDialog(
  context: ThemedReactContext,
) : Dialog(context) {
  @SuppressLint("UseCompatLoadingForDrawables")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window?.setBackgroundDrawableResource(android.R.color.transparent)
    val displayMetrics = context.resources.displayMetrics
    val isPortrait = displayMetrics.widthPixels < displayMetrics.heightPixels
    val maxWidth = if (isPortrait) displayMetrics.widthPixels else displayMetrics.heightPixels
    val maxHeight = if (isPortrait) (displayMetrics.heightPixels * 0.35).toInt() else (displayMetrics.heightPixels * 0.8).toInt()

    window?.setLayout(maxWidth, ViewGroup.LayoutParams.WRAP_CONTENT)

    window?.setGravity(Gravity.BOTTOM)
    window?.setWindowAnimations(com.google.android.material.R.style.Animation_Design_BottomSheetDialog)
  }

  override fun show() {
    super.show()
  }

}
