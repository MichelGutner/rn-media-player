package com.rnvideoplayer.mediaplayer.viewModels.components

import android.annotation.SuppressLint
import android.app.Dialog
import android.content.Context
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup

class CustomBottomDialog(
  context: Context,
) : Dialog(context) {
  @SuppressLint("UseCompatLoadingForDrawables")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window?.setBackgroundDrawableResource(android.R.color.transparent)
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
