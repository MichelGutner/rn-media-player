package com.rnvideoplayer.components

import ICustomPlayerControls
import android.annotation.SuppressLint
import android.graphics.drawable.AnimatedVectorDrawable
import android.view.View
import android.widget.ImageButton
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R

@SuppressLint("UseCompatLoadingForDrawables")
class CustomPlayerControls(private val context: ThemedReactContext, view: View) :
  ICustomPlayerControls {
  private val playPauseButton: ImageButton = view.findViewById(R.id.animated_play_to_pause)
  private val fullScreenButton: ImageButton = view.findViewById(R.id.animated_full_to_exit)
  private val settingsButton: ImageButton = view.findViewById(R.id.settings_control)
  private val replayButton: ImageButton = view.findViewById(R.id.replay_to_pause)

  private val animatedPlayToPause = createAnimatedDrawable(R.drawable.animated_play_to_pause)
  private val animatedPauseToPlay = createAnimatedDrawable(R.drawable.animated_pause_to_play)
  private val animatedFullSToExit = createAnimatedDrawable(R.drawable.animated_full_to_exit)
  private val animatedExitToFull = createAnimatedDrawable(R.drawable.animated_exit_to_full)

  override fun setPlayPauseButtonClickListener(listener: View.OnClickListener) {
    playPauseButton.setOnClickListener(listener)
  }

  override fun morphPlayPause(isPlaying: Boolean) {
    if (isPlaying) {
      replayButton.visibility = View.GONE
      playPauseButton.setImageDrawable(animatedPlayToPause)
      animatedPlayToPause.start()
    } else {
      playPauseButton.setImageDrawable(animatedPauseToPlay)
      animatedPauseToPlay.start()
    }
  }

  override fun setVisibilityPlayPauseButton(isVisible: Boolean) {
    playPauseButton.visibility = if (isVisible) View.VISIBLE else View.GONE
  }

  override fun setVisibilityReplayButton(isVisible: Boolean) {
    replayButton.visibility = if (isVisible) View.VISIBLE else View.GONE
  }

  override fun setFullScreenButtonClickListener(listener: View.OnClickListener) {
    fullScreenButton.setOnClickListener(listener)
  }

  override fun morphFullScreen(isFullScreen: Boolean) {
    if (isFullScreen) {
      fullScreenButton.setImageDrawable(animatedExitToFull)
      animatedExitToFull.start()
    } else {
      fullScreenButton.setImageDrawable(animatedFullSToExit)
      animatedFullSToExit.start()
    }
  }

  override fun setSettingsButtonClickListener(listener: View.OnClickListener) {
    settingsButton.setOnClickListener(listener)
  }

  override fun setReplayButtonClickListener(listener: View.OnClickListener) {
    replayButton.setOnClickListener(listener)
  }

  private fun createAnimatedDrawable(drawableResId: Int): AnimatedVectorDrawable {
    return this.context.getDrawable(drawableResId) as AnimatedVectorDrawable
  }
}
