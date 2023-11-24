package com.rnvideoplayer
import android.util.Log
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class RNVideoPlayer(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {


    override fun getName() = "RNVideoPlayer"


    @ReactMethod
    fun createCalendarEvent(name: String, location: String, callback: Callback) {
        val eventId = 123
        callback.invoke(eventId)
    }
}

