package com.rnvideoplayer.mediaplayer.viewModels

import android.annotation.SuppressLint
import android.app.Dialog
import android.os.Build
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.FrameLayout
import com.facebook.react.uimanager.ThemedReactContext

enum class EMediaPlayerFullscreen {
  NOT_FULLSCREEN, IN_TRANSITION, FULLSCREEN,
}

enum class EView {
  REGISTERED, UNREGISTERED,
}

interface MediaPlayerScreenListener {
  fun onScreenStateChanged(currentState: EMediaPlayerFullscreen)
  fun onView(state: EView, viewId: Int)
}

abstract class MediaPlayerContentScreen(context: ThemedReactContext) : FrameLayout(context) {
  private var subView: View? = null
  private val viewId = generateViewId()
  private var listener: MediaPlayerScreenListener? = null
  private val dialog: Dialog = Dialog(context, android.R.style.Theme_Black_NoTitleBar_Fullscreen)
  private val window: Window? = dialog.window

  init {
    buildFullscreenDialog()
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    buildFullscreenDialog()
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    listener = null
  }

  fun setListener(listener: MediaPlayerScreenListener) {
    this.listener = listener
  }

  fun enterFullscreen() {
    listener?.onScreenStateChanged(EMediaPlayerFullscreen.IN_TRANSITION)
    unregisterView()

    setDialogContent()

    if (dialog.isShowing) {
      listener?.onScreenStateChanged(EMediaPlayerFullscreen.FULLSCREEN)
      hideSystemBars()
    }
  }

  fun exitFullscreen() {
    listener?.onScreenStateChanged(EMediaPlayerFullscreen.IN_TRANSITION)
    unregisterView()

    setViewContent()

    if (!dialog.isShowing) {
      listener?.onScreenStateChanged(EMediaPlayerFullscreen.NOT_FULLSCREEN)
      restoreSystemBars()
    }
  }

  private fun setDialogContent() {
    if (subView != null) {
      dialog.setContentView(subView!!)
    }
    dialog.show()
  }

  private fun setViewContent() {
    (subView?.parent as? ViewGroup)?.addView(subView, viewId)
    dialog.dismiss()

    if (subView != null) {
      addView(subView)
    }
  }

  private fun unregisterView() {
    (subView?.parent as? ViewGroup)?.removeView(subView)
    listener?.onView(EView.UNREGISTERED, (subView?.id ?: 0))
  }

  fun registerView(contentView: View?) {
    subView = contentView
    addView(subView)
    listener?.onView(EView.REGISTERED, (subView?.id ?: 0))
  }

  @SuppressLint("ClickableViewAccessibility")
  private fun buildFullscreenDialog() {
    dialog.setOnDismissListener {
      exitFullscreen()
    }
  }

  private fun restoreSystemBars() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      window?.insetsController?.show(WindowInsets.Type.systemBars())
    } else {
      @Suppress("DEPRECATION")
      window?.decorView?.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
    }
  }

  private fun hideSystemBars() {
    window?.setFlags(
      WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
      WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
    )

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      window?.insetsController?.let { controller ->
        controller.hide(WindowInsets.Type.systemBars())
        controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
      }
    } else {
      @Suppress("DEPRECATION")
      window?.decorView?.systemUiVisibility = (
        View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
          View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
          View.SYSTEM_UI_FLAG_FULLSCREEN or
          View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
          View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
          View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
    }

    window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    removeCutoutShortEdges()
  }

  private fun removeCutoutShortEdges() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      val params = window!!.attributes
      params.layoutInDisplayCutoutMode =
        WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
      window.attributes = params
    }
  }
}
