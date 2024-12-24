package com.rnvideoplayer.mediaplayer.models

import android.content.Context
import android.view.View
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

object ReactEventsName {
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

  val registeredEvents = listOf(
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


open class ReactEventsAdapter(private val context: Context) {
   open fun send(eventName: String, view: View, writableMap: WritableMap) {
     val dispatcher = UIManagerHelper.getEventDispatcher(context as ReactContext?, view.id)
     if (dispatcher != null) {
       val surfaceId = UIManagerHelper.getSurfaceId(context)
       dispatcher.dispatchEvent(object : Event<Event<*>>(surfaceId, view.id) {
         override fun getEventName(): String {
           return eventName
         }

         override fun getEventData(): WritableMap {
           return writableMap
         }
       })
     }
   }
}
