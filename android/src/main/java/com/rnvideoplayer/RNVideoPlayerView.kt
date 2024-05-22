package com.rnvideoplayer

import CustomBottomDialog
import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PorterDuff
import android.media.MediaMetadataRetriever
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.RelativeLayout
import android.widget.TextView
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.DefaultTimeBar
import androidx.media3.ui.PlayerView
import androidx.media3.ui.TimeBar
import androidx.media3.ui.TimeBar.OnScrubListener
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.ThemedReactContext
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

private val ReadableMap.name: String
  get() {
    return this.getString("name").toString()
  }

private val ReadableMap.value: String
  get() {
    return this.getString("value").toString()
  }

private val ReadableMap.enabled: Boolean
  get() {
    return this.getBoolean("enabled")
  }

private val ReadableMap.children: ReadableMap?
  get() {
    return this.getMap("children")
  }

@UnstableApi
@SuppressLint(
  "ViewConstructor", "UseCompatLoadingForDrawables", "ResourceType",
  "MissingInflatedId"
)
class RNVideoPlayerView(context: ThemedReactContext) : PlayerView(context) {
  private val customPlayer = CustomExoPlayer(context, this)
  private val exoPlayer = customPlayer.getExoPlayer()
  private var viewController = customPlayer.getViewController()
  private var settingsProps: ReadableArray? = null

  private var isVisibleControl: Boolean = true
  private var isFullScreen: Boolean = false
  private var isSeeking: Boolean = false
  private val previewImageView: ImageView
  private val overlayView: RelativeLayout
  private var progressBar: ProgressBar
  private var seekBar: DefaultTimeBar
  private var contentView = context.currentActivity?.window?.decorView as ViewGroup
  private var timestamp = 0L
  private val interval = 5000L
  private val bitmaps = ArrayList<Bitmap>()

  private var timeCodesPosition: TextView
  private var timeCodesDuration: TextView
  private val dialog = CustomBottomDialog(context)
  private val controller = CustomPlayerControls(context, this)

  init {
    customPlayer.init()
    //        AspectRatioFrameLayout.LAYOUT_MODE_OPTICAL_BOUNDS.also { resizeMode = it }

    previewImageView = findViewById(R.id.preview_image_view)
    overlayView = findViewById(R.id.overlay_controls)



    progressBar = findViewById(R.id.progress_bar)
    seekBar = findViewById(R.id.animated_seekbar)
    progressBar.indeterminateDrawable.setColorFilter(Color.BLUE, PorterDuff.Mode.SRC_IN)
    timeCodesPosition = findViewById(R.id.time_codes_position)
    timeCodesDuration = findViewById(R.id.time_codes_duration)

    exoPlayer.addListener(object : Player.Listener {
      override fun onPlaybackStateChanged(playbackState: Int) {
        super.onPlaybackStateChanged(playbackState)

        if (playbackState === Player.STATE_BUFFERING) {
          controller.setVisibilityPlayPauseButton(false)
          progressBar.visibility = VISIBLE
        } else if (playbackState === Player.STATE_READY) {
          controller.setVisibilityPlayPauseButton(true)
          progressBar.visibility = GONE
          seekBar.setDuration(exoPlayer.duration)
          timeCodesDuration.text = createTimeCodesFormatted(exoPlayer.duration)
        }

        updateSeekBar()
      }

      override fun onPlayerError(error: PlaybackException) {
        // handle errors
      }
    })

    controller.setPlayPauseButtonClickListener {
      when  {
        exoPlayer.isPlaying -> exoPlayer.pause()
        else -> exoPlayer.play()
      }
      controller.morphPlayPause(exoPlayer.isPlaying)
    }

    controller.setFullScreenButtonClickListener {
      controller.morphFullScreen(isFullScreen)
      toggleFullScreen()
    }

    seekBar.addListener(object : OnScrubListener {
      override fun onScrubStart(timeBar: TimeBar, position: Long) {
        isSeeking = true
      }

      override fun onScrubMove(timeBar: TimeBar, position: Long) {
        val seconds = TimeUnit.MILLISECONDS.toSeconds(position)
        val duration = TimeUnit.MILLISECONDS.toSeconds(exoPlayer.duration)
        val intervalInSeconds = TimeUnit.MILLISECONDS.toSeconds(interval)
        val index = (seconds / intervalInSeconds).toInt()
        val counter = ((((seconds * 100) / duration) * seekBar.width) / 100)
        previewImageView.visibility = VISIBLE

        if (index < bitmaps.size) {
          previewImageView.setImageBitmap(bitmaps[index])
          previewImageView.translationX = getTranslateXPreviewImage(counter)
        }
      }

      override fun onScrubStop(timeBar: TimeBar, position: Long, canceled: Boolean) {
        if (!canceled) {
          exoPlayer.seekTo(position)
          previewImageView.visibility = GONE
          isSeeking = false
        }
      }

    })

    viewController.setOnClickListener {
      onToggleControlsVisibility()
    }

    controller.setSettingsButtonClickListener {
      dialog.show()
    }

    startSeekBarUpdateTask()
  }

  private fun getTranslateXPreviewImage(counter: Long): Float {
    var translateX: Float = 16.0F

    if (counter.toFloat() + previewImageView.width / 2 >= seekBar.width.toFloat()) {
      translateX = (seekBar.width.toFloat() - previewImageView.width) - 16
    } else if (counter.toFloat() >= previewImageView.width / 2 && counter.toFloat() + previewImageView.width / 2 < seekBar.width.toFloat()) {
      translateX = counter.toFloat() - previewImageView.width / 2
    }

    return translateX
  }

  private fun startSeekBarUpdateTask() {
    val updateIntervalMs = 1000L
    val updateIntervalOverlay = 5000L
    val updateSeekBarTask = object : Runnable {
      override fun run() {
        if (exoPlayer.playWhenReady && exoPlayer.isPlaying) {
          updateSeekBar()
        }
        postDelayed(this, updateIntervalMs)

//              if (isVisibleControl) {
//                Handler(Looper.getMainLooper()).postDelayed({
//                if (exoPlayer.isPlaying) hideControls()
//                }, updateIntervalOverlay)
//              }
      }
    }
    post(updateSeekBarTask)
  }

  fun setMediaItem(url: String) {
    val mediaItem = MediaItem.fromUri(android.net.Uri.parse(url))
    exoPlayer.setMediaItem(mediaItem)
    exoPlayer.prepare()
    generatingThumbnailFrames(url)
  }

  fun releasePlayer() {
    exoPlayer.release()
  }

  private fun updateSeekBar() {
    val position = exoPlayer.contentPosition
    val buffered = exoPlayer.contentBufferedPosition

    timeCodesPosition.text = createTimeCodesFormatted(position)
    seekBar.setPosition(position)
    seekBar.setBufferedPosition(buffered)
    seekBar.requestLayout()
  }

  private fun createTimeCodesFormatted(time: Long): String {
    val hours = TimeUnit.MILLISECONDS.toHours(time)
    val minutes = TimeUnit.MILLISECONDS.toMinutes(time)
    val seconds = TimeUnit.MILLISECONDS.toSeconds(time) - TimeUnit.MINUTES.toSeconds(minutes)

    return if (hours > 0) {
      String.format("%02d:%02d:%02d", minutes, seconds)
    } else {
      String.format("%02d:%02d", minutes, seconds)
    }
  }

  private fun toggleFullScreen() {
    if (isFullScreen) {
      contentView.removeView(this)
      contentView.addView(this, ViewGroup.LayoutParams.MATCH_PARENT, currentHeight)
    } else {
      contentView.removeView(this)
      contentView.addView(
        this,
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT
      )
    }
    isFullScreen = !isFullScreen
  }

  private fun generatingThumbnailFrames(url: String) {
    thread {
      val retriever = MediaMetadataRetriever()
      retriever.setDataSource(url)

      val durationString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
      val duration = durationString?.toLong() ?: 0

      while (timestamp < duration) {
        val bitmap =
          retriever.getFrameAtTime(timestamp * 1000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
        if (bitmap != null) {
          bitmaps.add(bitmap)
          timestamp += interval
        }
      }
      retriever.release()
    }
  }


  fun setCurrentHeight(height: Int) {
    currentHeight = height
  }

  private fun onToggleControlsVisibility() {
    if (!isVisibleControl) {
      // Controls are currently hidden, show them
      showControls()
    } else {
      // Controls are currently visible, hide them
      hideControls()
    }
  }

  private fun showControls() {
    isVisibleControl = true
    overlayView.fadeIn()
  }

  private fun hideControls() {
    isVisibleControl = false
    overlayView.fadeOut()
  }

  fun getSettingsProperties(props: ReadableMap) {
    settingsProps = props.getArray("data")
  }
}
