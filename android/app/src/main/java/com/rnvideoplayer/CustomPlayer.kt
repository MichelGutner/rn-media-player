package com.rnvideoplayer
import android.annotation.SuppressLint
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.drawable.AnimatedVectorDrawable
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.DefaultTimeBar
import androidx.media3.ui.PlayerView
import androidx.media3.ui.TimeBar
import androidx.media3.ui.TimeBar.OnScrubListener
import com.facebook.react.uimanager.ThemedReactContext
import java.util.concurrent.TimeUnit

@UnstableApi @SuppressLint("ViewConstructor", "UseCompatLoadingForDrawables")
class CustomPlayer constructor(context: ThemedReactContext): PlayerView(context) {
    private var isFullScreen: Boolean = false;
    private val playIcon: ImageView
    private val animatedPlayToPause: AnimatedVectorDrawable
    private val animatedPauseToPlay: AnimatedVectorDrawable
    private val fullScreenIcon: ImageView
    private val animatedFullSToExit: AnimatedVectorDrawable
    private val animatedExitToFull: AnimatedVectorDrawable
    private var progressBar: ProgressBar
    private var seekBar: DefaultTimeBar
    private val exoPlayer: ExoPlayer = ExoPlayer.Builder(context).build()
    private var contentView: ViewGroup

    private var timeCodesPosition: TextView
    private var timeCodesDuration: TextView
    init {
        player = exoPlayer
        useController = false
        AspectRatioFrameLayout.LAYOUT_MODE_OPTICAL_BOUNDS.also { resizeMode = it }
        exoPlayer.playWhenReady = true

        contentView = context.currentActivity?.window?.decorView as ViewGroup

        val inflater = LayoutInflater.from(context)
        inflater.inflate(R.layout.custom_player, this, true)
        playIcon = findViewById(R.id.animated_play_to_pause)
        fullScreenIcon = findViewById(R.id.animated_full_to_exit)
        progressBar = findViewById(R.id.progress_bar)
        seekBar = findViewById(R.id.animated_seekbar)
        progressBar.indeterminateDrawable.setColorFilter(Color.BLUE, PorterDuff.Mode.SRC_IN)
        timeCodesPosition = findViewById(R.id.time_codes_position)
        timeCodesDuration = findViewById(R.id.time_codes_duration)

        // Load the animated drawables
        animatedPlayToPause = context.getDrawable(R.drawable.animated_play_to_pause) as AnimatedVectorDrawable
        animatedPauseToPlay = context.getDrawable(R.drawable.animated_pause_to_play) as AnimatedVectorDrawable
        animatedFullSToExit = context.getDrawable(R.drawable.animated_full_to_exit) as AnimatedVectorDrawable
        animatedExitToFull = context.getDrawable(R.drawable.animated_exit_to_full) as AnimatedVectorDrawable

        exoPlayer.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                super.onPlaybackStateChanged(playbackState)

                if (playbackState === Player.STATE_BUFFERING) {
                    playIcon.visibility = INVISIBLE
                    progressBar.visibility = VISIBLE
                 } else if (playbackState === Player.STATE_READY) {
                     playIcon.visibility = VISIBLE
                    progressBar.visibility = GONE
                    seekBar.setDuration(exoPlayer.duration)
                    timeCodesDuration.text = createTimeCodesFormatted(exoPlayer.duration)
                }

                updateSeekBar()
            }

            override fun onPlayerError(error: PlaybackException) {
                // errors
            }
        })

        playIcon.setOnClickListener {
            if (exoPlayer.isPlaying) {
                playIcon.setImageDrawable(animatedPauseToPlay)
                animatedPauseToPlay.start()
                exoPlayer.pause()
            } else {
                playIcon.setImageDrawable(animatedPlayToPause)
                animatedPlayToPause.start()
                exoPlayer.play()
            }
        }

        fullScreenIcon.setOnClickListener {
            toggleFullScreen()
        }

        seekBar.addListener(object : OnScrubListener {
            override fun onScrubStart(timeBar: TimeBar, position: Long) {
                exoPlayer.seekTo(position)
            }

            override fun onScrubMove(timeBar: TimeBar, position: Long) {
                exoPlayer.seekTo(position)
            }

            override fun onScrubStop(timeBar: TimeBar, position: Long, canceled: Boolean) {
                if (!canceled) {
                    exoPlayer.seekTo(position)
                }
            }

        })


        startSeekBarUpdateTask()
    }

    override fun onConfigurationChanged(newConfig: Configuration?) {
        super.onConfigurationChanged(newConfig)
        val orientation = resources.configuration.orientation
        if (orientation === Configuration.ORIENTATION_LANDSCAPE) {

        }
    }
    private fun startSeekBarUpdateTask() {
        val updateIntervalMs = 1000L
        val updateSeekBarTask = object : Runnable {
            override fun run() {
                if (exoPlayer.playWhenReady && exoPlayer.isPlaying) {
                    updateSeekBar()
                }
                postDelayed(this, updateIntervalMs)
            }
        }
        post(updateSeekBarTask)
    }

    fun setMediaItem(url: String) {
        val mediaItem = MediaItem.fromUri(android.net.Uri.parse(url))
        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.prepare()
    }

    fun relesePlayer() {
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

    private  fun createTimeCodesFormatted(time: Long): String {
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
            fullScreenIcon.setImageDrawable(animatedExitToFull)
            animatedExitToFull.start()

            contentView.removeView(this)
            contentView.addView(this, ViewGroup.LayoutParams.MATCH_PARENT, currentHeight)
        } else {
            fullScreenIcon.setImageDrawable(animatedFullSToExit)
            animatedFullSToExit.start()

            contentView.removeView(this)
            contentView.addView(this, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        }
        isFullScreen = !isFullScreen
    }

    fun setCurrentHeight(height: Int) {
        currentHeight = height
    }
}