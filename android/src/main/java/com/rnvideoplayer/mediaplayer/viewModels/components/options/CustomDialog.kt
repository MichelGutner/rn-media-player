package com.rnvideoplayer.mediaplayer.viewModels.components.options

import android.annotation.SuppressLint
import android.app.Dialog
import android.content.Context
import android.content.pm.ActivityInfo
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup

class CustomDialog(
  context: Context,
) : Dialog(context) {
  @SuppressLint("UseCompatLoadingForDrawables", "PrivateResource")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window?.setBackgroundDrawableResource(android.R.color.transparent)
    val displayMetrics = context.resources.displayMetrics
    val isPortrait = context.resources?.configuration?.orientation == ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    val maxWidth = if (isPortrait) displayMetrics.widthPixels else displayMetrics.heightPixels

    window?.setLayout(maxWidth, ViewGroup.LayoutParams.WRAP_CONTENT)

    window?.setGravity(Gravity.BOTTOM)
    window?.setWindowAnimations(com.google.android.material.R.style.Animation_Material3_BottomSheetDialog)
  }
}
