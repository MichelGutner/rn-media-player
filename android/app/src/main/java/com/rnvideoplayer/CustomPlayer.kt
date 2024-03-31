package com.rnvideoplayer
import android.annotation.SuppressLint
import android.graphics.drawable.AnimatedVectorDrawable
import android.view.LayoutInflater
import android.widget.ImageView
import com.facebook.react.uimanager.ThemedReactContext
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.SimpleExoPlayer
import com.google.android.exoplayer2.ui.PlayerView

@SuppressLint("ViewConstructor", "UseCompatLoadingForDrawables")
class CustomPlayer constructor(context: ThemedReactContext): PlayerView(context) {
    private val exoPlayer: SimpleExoPlayer = SimpleExoPlayer.Builder(context).build()

    private val playIcon: ImageView
    private val animatedPlayToPause: AnimatedVectorDrawable
    private val animatedPauseToPlay: AnimatedVectorDrawable

    private var isPlaying: Boolean = false

    private var switchNumber: Int = 0;

    init {
        player = exoPlayer
        exoPlayer.playWhenReady = true

        val inflater = LayoutInflater.from(context)
        inflater.inflate(R.layout.custom_player_layout, this, true)
        playIcon = findViewById(R.id.animated_play_to_pause)

        // Load the animated drawables
        animatedPlayToPause = context.getDrawable(R.drawable.animated_play_to_pause) as AnimatedVectorDrawable
        animatedPauseToPlay = context.getDrawable(R.drawable.animated_pause_to_play) as AnimatedVectorDrawable

        // Set up click listener for the play icon
        playIcon.setOnClickListener {
            // Toggle between play and pause states
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
    }

    fun setMediaItem(url: String) {
        val mediaItem = MediaItem.fromUri(android.net.Uri.parse(url))
        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.prepare()
    }

    fun hideControls() {
        useController = false
    }

    fun relesePlayer() {
       exoPlayer.release()
    }
}