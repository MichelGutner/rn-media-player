package com.rnvideoplayer.events

import android.content.Context
import android.view.View
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

val events = listOf(
  "onMenuItemSelected",
  "onMediaProgress",
  "onMediaLoaded",
  "onMediaCompleted",
  "onMediaReady",
  "onMediaBuffer",
  "onMediaBufferCompleted",
  "onMediaPlayPause",
  "onMediaError",
  "onMediaSeekBar",
  "onMediaPinchZoom"
)

class Events(private val context: Context) {

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
