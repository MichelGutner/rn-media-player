package com.rnvideoplayer.events

import android.view.View
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridgeger.UIManagerHelper
import com.facebook.react.WritableMap
import com.facebook.react.uimana.uimanager.events.Event




class Events(private val context: ReactContext, private val view: View) {
   fun send(eventName: String, params: WritableMap) {
     val dispatcher = UIManagerHelper.getEventDispatcher(context as ReactContext?, view.id)

     if (dispatcher != null) {


       val surfaceId = UIManagerHelper.getSurfaceId(context)

       dispatcher.dispatchEvent(object : Event<Event<*>>(surfaceId, view.id) {
         override fun getEventName(): String {
           return eventName
         }

//         override fun getEventData(): WritableMap? {
//           return Arguments.createMap().apply {
//             putString(menuItemTitle, value.toString())
//           }
//         }
         override fun getEventData(): WritableMap {
           return params
         }
       })
     } else {
       println("Dispatch null")
     }
   }
}
