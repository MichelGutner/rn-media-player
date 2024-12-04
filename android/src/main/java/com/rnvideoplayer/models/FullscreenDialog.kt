package com.rnvideoplayer.models

import android.app.Dialog
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import com.facebook.react.uimanager.ThemedReactContext

class FullscreenPlayerDialog(
  private var context: ThemedReactContext,
) : Dialog(context, android.R.style.Theme_Black_NoTitleBar_Fullscreen) {

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    window?.decorView?.systemUiVisibility = (
      View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
        View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
        View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
        View.SYSTEM_UI_FLAG_LAYOUT_STABLE
      )

    window?.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)

    val container = FrameLayout(context).apply {
      layoutParams = FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT
      )
    }

    setContentView(container)
  }
}
