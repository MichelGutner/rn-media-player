package com.rnvideoplayer.components

import ICustomPlayerControls
import android.annotation.SuppressLint
import android.graphics.drawable.AnimatedVectorDrawable
import android.view.View
import android.view.View.OnClickListener
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.RelativeLayout
import android.widget.TextView
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.EventNames
import com.rnvideoplayer.R
import com.rnvideoplayer.helpers.TimeoutWork
import com.rnvideoplayer.utils.fadeIn
import com.rnvideoplayer.utils.fadeOut

@SuppressLint("UseCompatLoadingForDrawables")
class CustomPlayerControls(private val context: ThemedReactContext, view: View) :
  ICustomPlayerControls {
  val timeoutWork = TimeoutWork()

  val overlayView: View = view.findViewById(R.id.overlay_controls)
  private val playerView: View = view.findViewById(R.id.player)

  val playPauseBackground by lazy { view.findViewById<RelativeLayout>(R.id.play_pause_background) }

  private val playPauseButton: ImageButton? = view.findViewById(R.id.animated_play_to_pause)
  private val fullScreenButton: ImageButton? = view.findViewById(R.id.animated_full_to_exit)
  private val settingsButton: ImageButton? = view.findViewById(R.id.settings_control)
  private val replayButton: ImageButton? = view.findViewById(R.id.replay_to_pause)
  val timeCodesPosition: TextView? = view.findViewById(R.id.time_codes_position)
  val timeCodesDuration: TextView? = view.findViewById(R.id.time_codes_duration)

  private val animatedPlayToPause = createAnimatedDrawable(R.drawable.animated_play_to_pause)
  private val animatedPauseToPlay = createAnimatedDrawable(R.drawable.animated_pause_to_play)
  private val animatedFullSToExit = createAnimatedDrawable(R.drawable.animated_full_to_exit)
  private val animatedExitToFull = createAnimatedDrawable(R.drawable.animated_exit_to_full)

  override fun setPlayPauseButtonClickListener(listener: View.OnClickListener) {
    playPauseButton?.setOnClickListener(listener)
  }

  override fun morphPlayPause(isPlaying: Boolean) {
    if (isPlaying) {
      replayButton?.visibility = View.GONE
      playPauseButton?.setImageDrawable(animatedPlayToPause)
      animatedPlayToPause.start()
    } else {
      playPauseButton?.setImageDrawable(animatedPauseToPlay)
      animatedPauseToPlay.start()
    }
  }

  override fun setPlayerViewClickListener(listener: OnClickListener) {
    playerView.setOnClickListener(listener)
  }

  override fun setVisibilityPlayPauseButton(isVisible: Boolean) {
    playPauseButton?.visibility = if (isVisible) View.VISIBLE else View.INVISIBLE
  }

  override fun setVisibilityReplayButton(isVisible: Boolean) {
    replayButton?.visibility = if (isVisible) View.VISIBLE else View.INVISIBLE
  }

  override fun setFullScreenButtonClickListener(listener: View.OnClickListener) {
    fullScreenButton?.setOnClickListener(listener)
  }

  override fun morphFullScreen(isFullScreen: Boolean) {
    if (isFullScreen) {
      fullScreenButton?.setImageDrawable(animatedExitToFull)
      animatedExitToFull.start()
    } else {
      fullScreenButton?.setImageDrawable(animatedFullSToExit)
      animatedFullSToExit.start()
    }
  }

  override fun setSettingsButtonClickListener(listener: View.OnClickListener) {
    settingsButton?.setOnClickListener(listener)
  }

  override fun setReplayButtonClickListener(listener: View.OnClickListener) {
    replayButton?.setOnClickListener(listener)
  }

  override fun timeoutControls() {
    timeoutWork.cancelTimer()

    timeoutWork.createTask(4000) {
      hideControls()
    }
  }

  override fun showControls() {
    overlayView.fadeIn()
  }

  override fun hideControls() {
    overlayView.fadeOut()
  }

  private fun createAnimatedDrawable(drawableResId: Int): AnimatedVectorDrawable {
    return this.context.getDrawable(drawableResId) as AnimatedVectorDrawable
  }
}
