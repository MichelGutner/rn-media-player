package com.rnvideoplayer.mediaplayer.viewModels

import android.annotation.SuppressLint
import android.app.Dialog
import android.content.pm.ActivityInfo
import android.os.Build
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.FrameLayout
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.mediaplayer.logger.Debug

enum class EMediaPlayerFullscreen {
  NOT_FULLSCREEN, IN_TRANSITION, FULLSCREEN,
}

enum class EView {
  REGISTERED, UNREGISTERED,
}

interface MediaPlayerScreenListener {
  fun onScreenStateChanged(currentState: EMediaPlayerFullscreen, currentSensor: Int? = null)
  fun onView(state: EView, viewId: Int)
}

abstract class MediaPlayerContentScreen(private val context: ThemedReactContext) :
  FrameLayout(context) {
    private var oldLayoutParams: ViewGroup.LayoutParams? = null
  private var subView: View? = null
  private val viewId = generateViewId()
  private var listener: MediaPlayerScreenListener? = null
  private val dialog: Dialog = Dialog(context, android.R.style.Theme_Black_NoTitleBar_Fullscreen)
  private val window: Window? = dialog.window

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

  fun onEnterFullscreen(onCompletion: (() -> Unit) = {}, currentSensor: Int? = null) {
    listener?.onScreenStateChanged(EMediaPlayerFullscreen.IN_TRANSITION)
    unregisterView()
    registerToDialogView()

    if (dialog.isShowing) {
      listener?.onScreenStateChanged(EMediaPlayerFullscreen.FULLSCREEN, currentSensor)
      hideSystemBars()
      onCompletion.invoke()
    }
  }

  fun onExitFullscreen(onCompletion: () -> Unit = {}) {
    listener?.onScreenStateChanged(EMediaPlayerFullscreen.IN_TRANSITION)
    removeView()
    registerToSimpleView()

    if (!dialog.isShowing) {
      listener?.onScreenStateChanged(EMediaPlayerFullscreen.NOT_FULLSCREEN)
      restoreSystemBars()
      onCompletion.invoke()
    }
  }

  fun removeView() {
    unregisterView()
    dialog.dismiss()
  }

  private fun registerToDialogView() {
    if (subView != null) {
      dialog.setContentView(subView!!)
    }
    dialog.show()
  }

  private fun registerToSimpleView() {
    if (subView != null) {
      addView(subView)
      context.currentActivity?.run {
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT
      }
    }
  }

  private fun unregisterView() {
    oldLayoutParams = subView?.layoutParams
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
      onExitFullscreen()
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
