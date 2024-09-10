package com.rnvideoplayer.events

import android.view.View
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

val events = listOf(
  "onMenuItemSelected",
  "onVideoProgress",
  "onLoaded",
  "onCompleted",
  "onReady",
  "onBuffer",
  "onBufferCompleted",
  "onPlayPause",
  "onError"
)

class Events(private val context: ReactContext) {
   fun send(eventName: String, view: View, params: WritableMap) {
     val dispatcher = UIManagerHelper.getEventDispatcher(context as ReactContext?, view.id)

     if (dispatcher != null) {


       val surfaceId = UIManagerHelper.getSurfaceId(context)

       dispatcher.dispatchEvent(object : Event<Event<*>>(surfaceId, view.id) {
         override fun getEventName(): String {
           return eventName
         }

         override fun getEventData(): WritableMap {
           return params
         }
       })
     }
   }
}
