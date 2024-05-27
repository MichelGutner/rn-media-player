package com.rnvideoplayer.exoPlayer

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R

class CustomExoPlayer(private val context: ThemedReactContext, private val view: PlayerView) {
    private val exoPlayer: ExoPlayer = ExoPlayer.Builder(context).build();
  init {
    val inflater = LayoutInflater.from(context)
    inflater.inflate(R.layout.custom_player, view, true)
  }

  fun init()  {
    view.player = exoPlayer
    view.useController = false
    exoPlayer.prepare()
    exoPlayer.playWhenReady = true
  }

  fun getExoPlayer() : ExoPlayer {
    return exoPlayer
  }

  fun getOverlayView() : PlayerView {
    return view.findViewById(R.id.player)
  }

  fun getParentView() : ViewGroup {
    return context.currentActivity?.window?.decorView as ViewGroup
  }
}
