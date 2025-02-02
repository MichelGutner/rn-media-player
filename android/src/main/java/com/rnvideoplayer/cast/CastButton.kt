package com.rnvideoplayer.cast

import android.annotation.SuppressLint
import android.os.Handler
import android.os.Looper
import android.widget.FrameLayout
import androidx.core.content.ContextCompat
import androidx.core.view.setPadding
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.media3.common.util.UnstableApi
import androidx.mediarouter.app.MediaRouteButton
import com.facebook.react.uimanager.ThemedReactContext
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.CastStateListener
import com.google.android.gms.cast.framework.IntroductoryOverlay
import com.google.android.gms.cast.framework.SessionManagerListener
import com.rnvideoplayer.R
import com.rnvideoplayer.mediaplayer.logger.Debug
import java.util.concurrent.Executors
import android.content.Intent
import android.net.Uri
import java.util.concurrent.Executor


@SuppressLint("ViewConstructor")
@UnstableApi
class CastButton(private val reactContext: ThemedReactContext) : FrameLayout(reactContext) {
  private var mCastContext: CastContext? = null
  private val mSessionManagerListener: SessionManagerListener<CastSession> = MySessionManagerListener()
  private var mCastSession: CastSession? = null
  private var mIntroductoryOverlay: IntroductoryOverlay? = null
  private var mCastStateListener: CastStateListener? = null
  private val castExecutor: Executor = Executors.newSingleThreadExecutor();
  private var hasValidCastContextOnResume = false

  private var size: Int = 60
  private val mMediaRouteButton = MediaRouteButton(reactContext).apply {
    setPadding(12)
  }

  init {
    setupLayout()
    setupMediaRouteButton()
    initializeCastContext()
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
  }

  private fun initializeCastContext() {
    mCastContext = CastContext.getSharedInstance(reactContext)

    val castContextTask = CastContext.getSharedInstance(reactContext, castExecutor)
    castContextTask.addOnCompleteListener { task ->
      if (task.isSuccessful) {
        onCastContextInitialized(task.result!!)
      } else {
        Debug.log("$TAG fail to initialize CastContext")
      }
    }
  }

  private fun setupMediaRouteButton() {
    mMediaRouteButton.setRemoteIndicatorDrawable(
      ContextCompat.getDrawable(reactContext, R.drawable.baseline_cast_24)
    )

    CastContext.getSharedInstance(reactContext)
    CastButtonFactory.setUpMediaRouteButton(context, mMediaRouteButton)
    addView(mMediaRouteButton)

    showIntroductoryOverlay()
  }

  @Synchronized
  private fun onCastContextInitialized(castContext: CastContext) {
    mCastContext = castContext
    mCastContext!!.sessionManager.addSessionManagerListener(
      mSessionManagerListener, CastSession::class.java
    )
    mCastContext!!.addSessionTransferCallback(
      CastSessionTransferCallback(reactContext.applicationContext)
    )
    val activity = reactContext.currentActivity as LifecycleOwner

    if (activity.lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED) && !hasValidCastContextOnResume) {
      onResumeWithCastContext(castContext)
    }
  }

  @Synchronized
  private fun onResumeWithCastContext(castContext: CastContext) {
    castContext.addCastStateListener(mCastStateListener!!)
    intentToJoin()
    if (mCastSession == null) {
      mCastSession = castContext.sessionManager.currentCastSession
    }

    hasValidCastContextOnResume = true
  }

  private fun setupLayout() {
    layoutParams = LayoutParams(size, size)
  }

  private fun intentToJoin() {
    val intent = Intent()
    val intentToJoinUri = Uri.parse("https://castvideos.com/cast/join")
    if (intent.data != null && intent.data == intentToJoinUri) {
      mCastContext!!.sessionManager.startSession(intent)
    }
  }

  private fun showIntroductoryOverlay() {
    if (mIntroductoryOverlay != null) {
      mIntroductoryOverlay!!.remove()
    }
    Handler(Looper.getMainLooper()).post {
      mIntroductoryOverlay = IntroductoryOverlay.Builder(
        reactContext.currentActivity!!, mMediaRouteButton
      )
        .setTitleText(R.string.introducing_cast)
        .setSingleTime()
        .setOnOverlayDismissedListener { mIntroductoryOverlay = null }
        .build()
      mIntroductoryOverlay!!.show()
    }
  }


  private inner class MySessionManagerListener : SessionManagerListener<CastSession> {
    override fun onSessionStarted(session: CastSession, sessionId: String) {
      mCastSession = session
    }

    override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
      mCastSession = session
    }

    override fun onSessionEnded(session: CastSession, error: Int) {
      mCastSession = null
    }

    override fun onSessionStarting(session: CastSession) {}
    override fun onSessionStartFailed(session: CastSession, error: Int) {}
    override fun onSessionEnding(session: CastSession) {}
    override fun onSessionResuming(session: CastSession, sessionId: String) {}
    override fun onSessionResumeFailed(session: CastSession, error: Int) {}
    override fun onSessionSuspended(session: CastSession, reason: Int) {}
  }

  companion object {
    private const val TAG = "CastPlayerButton"
  }
}

