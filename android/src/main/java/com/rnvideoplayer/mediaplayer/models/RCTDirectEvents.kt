package com.rnvideoplayer.mediaplayer.models

import android.content.Context
import android.util.Log
import android.view.View
import androidx.media3.common.PlaybackException
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

open class RCTDirectEvents(private val context: Context, private val view: View) {
  private fun dispatchEvent(eventName: String, block: WritableMap.() -> Unit) {
    val dispatcher = UIManagerHelper.getEventDispatcher(context as ReactContext?, view.id)
    if (dispatcher != null) {
      val surfaceId = UIManagerHelper.getSurfaceId(context)
      val eventData = Arguments.createMap().apply { block() }
      val event = object : Event<Event<*>>(surfaceId, view.id) {
        override fun getEventName(): String  {
          return eventName
        }
        override fun getEventData(): WritableMap  {
          return eventData
        }
      }
      dispatcher.dispatchEvent(event)
    }
  }

  fun onFullScreenStateChanged(isFullscreen: Boolean) {
    Log.d(TAG, "Event: ${RCTEvents.FULL_SCREEN_STATE_CHANGED}, Fullscreen state: $isFullscreen")
    dispatchEvent(RCTEvents.FULL_SCREEN_STATE_CHANGED) {
      putBoolean("isFullscreen", isFullscreen)
    }
  }


  fun onMediaPinchZoom(currentZoom: String) {
    dispatchEvent(RCTEvents.MEDIA_PINCH_ZOOM) {
      putString("currentZoom", currentZoom)
    }
  }

  fun onMenuItemSelected(itemName: String, itemValue: String) {
    dispatchEvent(RCTEvents.MENU_ITEM_SELECTED) {
      putString("name", itemName)
      putString("value", itemValue)
    }
  }

  fun onMediaReady(duration: Double) {
    dispatchEvent(RCTEvents.MEDIA_READY) {
      putDouble("duration", duration)
      putBoolean("loaded", true)
    }
  }

  fun onMediaCompleted() {
    dispatchEvent(RCTEvents.MEDIA_COMPLETED) {
      putBoolean("completed", true)
    }
  }

  fun onMediaBuffering(progress: Double, totalBuffered: Double) {
    dispatchEvent(RCTEvents.MEDIA_BUFFERING) {
      putDouble("progress", progress)
      putDouble("totalBuffered", totalBuffered)
    }
  }

  fun onMediaPlayPause(isPlaying: Boolean) {
    dispatchEvent(RCTEvents.MEDIA_PLAY_PAUSE) {
      putBoolean("isPlaying", isPlaying)
    }
  }

  fun onMediaError(domain: String, error: PlaybackException?, userInfo: String) {
    dispatchEvent(RCTEvents.MEDIA_ERROR) {
      putString("domain", domain)
      putString("error", error?.cause.toString())
      error?.errorCode?.let { putDouble("code", it.toDouble()) }
      putString("userInfo", userInfo)
    }
  }

  fun onMediaBufferCompleted() {
    dispatchEvent(RCTEvents.MEDIA_BUFFER_COMPLETED) {
      putBoolean("completed", true)
    }
  }

  fun onMediaSeekBar(startPercent: Double, startSeconds: Double, endPercent: Double, endSeconds: Double) {
    dispatchEvent(RCTEvents.MEDIA_SEEK_BAR) {
      val startMap = Arguments.createMap().apply {
        putDouble("percent", startPercent)
        putDouble("seconds", startSeconds)
      }

      val endMap = Arguments.createMap().apply {
        putDouble("percent", endPercent)
        putDouble("seconds", endSeconds)
      }
      putMap("start", startMap)
      putMap("end", endMap)
    }
  }

  companion object {
    private val TAG = RCTDirectEvents::class.java.simpleName
  }
}


object RCTEvents {
  const val MENU_ITEM_SELECTED = "onMenuItemSelected"
  const val MEDIA_READY = "onMediaReady"
  const val MEDIA_COMPLETED = "onMediaCompleted"
  const val MEDIA_BUFFERING = "onMediaBuffering"
  const val MEDIA_PLAY_PAUSE = "onMediaPlayPause"
  const val MEDIA_ERROR = "onMediaError"
  const val MEDIA_BUFFER_COMPLETED = "onMediaBufferCompleted"
  const val MEDIA_SEEK_BAR = "onMediaSeekBar"
  const val MEDIA_PINCH_ZOOM = "onMediaPinchZoom"
  const val FULL_SCREEN_STATE_CHANGED = "onFullScreenStateChanged"

  val rctRegisteredEvents = listOf(
    MENU_ITEM_SELECTED,
    MEDIA_READY,
    MEDIA_COMPLETED,
    MEDIA_BUFFERING,
    MEDIA_BUFFER_COMPLETED,
    MEDIA_PLAY_PAUSE,
    MEDIA_ERROR,
    MEDIA_SEEK_BAR,
    MEDIA_PINCH_ZOOM,
    FULL_SCREEN_STATE_CHANGED
  )
}
