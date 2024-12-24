package com.rnvideoplayer.cast

import android.annotation.SuppressLint
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.widget.FrameLayout
import androidx.core.content.ContextCompat
import androidx.media3.cast.CastPlayer
import androidx.media3.common.util.Log
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.mediarouter.app.MediaRouteButton
import com.facebook.react.uimanager.ThemedReactContext
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.CastStateListener
import com.google.android.gms.cast.framework.IntroductoryOverlay
import com.google.android.gms.cast.framework.SessionManager
import com.google.android.gms.cast.framework.SessionManagerListener
import com.rnvideoplayer.R
import java.util.concurrent.Executor
import java.util.concurrent.Executors

@SuppressLint("ViewConstructor")
@UnstableApi
class CastPlayerButton(private val context: ThemedReactContext, private val exoPlayer: ExoPlayer) : FrameLayout(context) {
  private var mSessionManagerListener: SessionManagerListener<CastSession>? = null
  private var mCastSession: CastSession? = null
  private var mCastContext: CastContext? = null
  private var mCastStateListener: CastStateListener? = null
  private var mIntroductoryOverlay: IntroductoryOverlay? = null
  private val  castExecutor: Executor = Executors.newSingleThreadExecutor();
  private val mMediaRouteButton = MediaRouteButton(context)
  private lateinit var mSessionManager: SessionManager

  init {
    mMediaRouteButton.setRemoteIndicatorDrawable(ContextCompat.getDrawable(context, R.drawable.baseline_cast_24))
    CastButtonFactory.setUpMediaRouteButton(context, mMediaRouteButton)

    val layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
      gravity = Gravity.TOP or Gravity.END
    }
    addView(mMediaRouteButton, layoutParams)
  }

  private fun showIntroductoryOverlay() {
    if (mIntroductoryOverlay != null) {
      mIntroductoryOverlay!!.remove()
    }
      Handler(Looper.getMainLooper()).post {
        mIntroductoryOverlay = IntroductoryOverlay.Builder(
          context.currentActivity!!, mMediaRouteButton
        )
          .setTitleText(R.string.introducing_cast)
          .setOverlayColor(androidx.media3.cast.R.color.cast_intro_overlay_background_color)
          .setSingleTime()
          .setOnOverlayDismissedListener { mIntroductoryOverlay = null }
          .build()
        mIntroductoryOverlay!!.show()
      }
  }

  companion object {
    private const val TAG = "CastPlayerButton"
  }
}
