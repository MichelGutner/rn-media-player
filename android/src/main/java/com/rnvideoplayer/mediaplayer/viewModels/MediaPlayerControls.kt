package com.rnvideoplayer.mediaplayer.viewModels

import android.content.Context
import android.util.TypedValue
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.core.view.isVisible
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.TimeBar
import com.rnvideoplayer.fadeIn
import com.rnvideoplayer.fadeOut
import com.rnvideoplayer.mediaplayer.models.MediaPlayerAdapter
import com.rnvideoplayer.mediaplayer.interfaces.IMediaPlayerControls
import com.rnvideoplayer.mediaplayer.viewModels.components.FullscreenButton
import com.rnvideoplayer.mediaplayer.viewModels.components.PlayPauseButton
import com.rnvideoplayer.mediaplayer.viewModels.components.SeekBar
import com.rnvideoplayer.mediaplayer.viewModels.components.Title
import com.rnvideoplayer.mediaplayer.utils.Utils
import java.util.concurrent.TimeUnit

@UnstableApi
abstract class MediaPlayerControls(context: Context) : FrameLayout(context), IMediaPlayerControls {
  val overlayView = createOverlayView()

  private val mediaPlayer = MediaPlayerAdapter(context)
  private val playPauseButton by lazy { PlayPauseButton(context) }
  private val fullscreenButton by lazy { FullscreenButton(context) }
  private val seekBar by lazy { SeekBar(context) }
  private val title by lazy { Title(context) }

  private val bottomControls = customFrameLayout()
  private val linearLayout = customLinearVerticalLayout()

  private var isFullscreen = false
  private var isFinished = false

  val surfaceView = mediaPlayer.surfaceView

  init {
    setupMediaPlayerCallbacks()
    setupOverlayComponents()
    seekBarListener()
  }

  private fun seekBarListener() {
    seekBar.onScrubListener(object : TimeBar.OnScrubListener {
      override fun onScrubStart(seekBar: TimeBar, position: Long) {
        //
      }

      override fun onScrubMove(seekBar: TimeBar, position: Long) {
        //
      }

      override fun onScrubStop(seekBar: TimeBar, position: Long, canceled: Boolean) {
        val duration = TimeUnit.MILLISECONDS.toSeconds(mediaPlayer.duration)
        val seconds = TimeUnit.MILLISECONDS.toSeconds(position)

        if (seconds < duration) {
          isFinished = false
        }

        if (!canceled) {
          mediaPlayer.seekTo(position)
        }
      }
    })
  }

  private fun setupMediaPlayerCallbacks() {
    mediaPlayer.addCallback(object : MediaPlayerAdapter.Callback {
      override fun onMediaLoaded(duration: Long) {
        seekBar.build(duration)
      }

      override fun onPlaybackStateChanged(isPlaying: Boolean) {
        playPauseButton.updatePlayPauseIcon(isPlaying)
      }

      override var shouldShowPlayPause: Boolean
        get() = true
        set(value) {}

      override fun onMediaError(error: PlaybackException?) {
        //
      }

      override fun onMediaBuffering(currentProgress: Long, bufferedProgress: Long) {
        seekBar.update(currentProgress, bufferedProgress)
      }

      override fun getMediaMetadata(mediaMetadata: MediaMetadata) {
        title.setTitle(mediaMetadata.title.toString())
      }
    })
  }

  private fun setupOverlayComponents() {
    playPauseButton.setOnClickListener {
      mediaPlayer.togglePlayPause()
    }
    fullscreenButton.setOnClickListener {
      toggleFullscreen()
    }

    playPauseButton.setSize(dpToPx(60f))
    fullscreenButton.setSize(dpToPx(40f))

    linearLayout.addView(fullscreenButton)
    linearLayout.addView(seekBar)

    bottomControls.addView(linearLayout)

    overlayView.addView(title)
    overlayView.addView(playPauseButton)
    overlayView.addView(bottomControls)
  }

  private fun toggleFullscreen() {
    onFullscreenMode(!isFullscreen)
    fullscreenButton.updateFullscreenIcon(!isFullscreen)
    isFullscreen = !isFullscreen
  }

  private fun createOverlayView(): FrameLayout {
    val padding = dpToPx(16f)
    return FrameLayout(context).apply {
      setBackgroundColor(Utils.COLOR_BLACK_ALPHA_03)
      layoutParams = LayoutParams(
        LayoutParams.MATCH_PARENT,
        LayoutParams.MATCH_PARENT
      )
      setPadding(padding,padding,padding,padding)
    }
  }

  private fun dpToPx(dp: Float): Int {
    return TypedValue.applyDimension(
      TypedValue.COMPLEX_UNIT_DIP,
      dp,
      context.resources.displayMetrics
    ).toInt()
  }

  private fun customFrameLayout() : FrameLayout {
    return FrameLayout(context).apply {
      layoutParams = LayoutParams(
        LayoutParams.MATCH_PARENT,
        LayoutParams.WRAP_CONTENT,
      ).apply {
      gravity = Gravity.BOTTOM
      }
    }
  }

  private fun customLinearVerticalLayout() : LinearLayout {
    return LinearLayout(context).apply {
      layoutParams = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.WRAP_CONTENT,
      ).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.END
      }
    }
  }

  fun toggleOverlayVisibility() {
    if (overlayView.isVisible) {
      overlayView.fadeOut()
    } else {
      overlayView.fadeIn()
    }
  }

  fun mediaPlayerRelease() {
    mediaPlayer.release()
  }

  fun setupMediaPlayer(url: String, startTime: Long? = 0, metadata: MediaMetadata? = null) {
    mediaPlayer.onBuild(url, startTime, metadata)
  }

  fun onAutoPlay(autoPlayer: Boolean) {
    mediaPlayer.onAutoPlay(autoPlayer)
  }
}

