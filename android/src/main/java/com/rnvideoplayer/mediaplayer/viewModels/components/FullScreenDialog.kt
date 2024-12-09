package com.rnvideoplayer.mediaplayer.viewModels.components

import android.app.Dialog
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import com.facebook.react.uimanager.ThemedReactContext

class FullscreenDialog(
  private var context: ThemedReactContext,
) : Dialog(context, android.R.style.Theme_Black_NoTitleBar_Fullscreen) {

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    @Suppress("DEPRECATION")
    window?.decorView?.systemUiVisibility = (
      View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
        View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
        View.SYSTEM_UI_FLAG_FULLSCREEN or
        View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
        View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
        View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
      )

    window?.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
  }
}
