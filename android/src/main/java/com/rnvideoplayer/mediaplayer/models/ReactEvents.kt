package com.rnvideoplayer.mediaplayer.models

import android.content.Context
import android.view.View
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

object ReactEventsName {
  const val MENU_ITEM_SELECTED = "onMenuItemSelected"
  const val MEDIA_PROGRESS = "onMediaProgress"
  const val MEDIA_READY = "onMediaReady"
  const val MEDIA_COMPLETED = "onMediaCompleted"
  const val MEDIA_BUFFERING = "onMediaBuffer"
  const val MEDIA_PLAY_PAUSE = "onMediaPlayPause"
  const val MEDIA_ERROR = "onMediaError"
  const val MEDIA_BUFFER_COMPLETED = "onMediaBufferCompleted"
  const val MEDIA_SEEK_BAR = "onMediaSeekBar"
  const val MEDIA_PINCH_ZOOM = "onMediaPinchZoom"

  val list = listOf(
    MENU_ITEM_SELECTED,
    MEDIA_PROGRESS,
    MEDIA_READY,
    MEDIA_COMPLETED,
    MEDIA_BUFFERING,
    MEDIA_BUFFER_COMPLETED,
    MEDIA_PLAY_PAUSE,
    MEDIA_ERROR,
    MEDIA_SEEK_BAR,
    MEDIA_PINCH_ZOOM
  )
}


class ReactEvents(private val context: Context) {
   fun send(eventName: String, view: View, writableMap: WritableMap) {
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
