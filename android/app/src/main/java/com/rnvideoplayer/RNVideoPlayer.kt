package com.rnvideoplayer
import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class RNVideoPlayer(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {


    override fun getName() = "RNVideoPlayer"


    @ReactMethod
    fun createCalendarEvent(name: String, location: String) {
        Log.d("CalendarModule", "Create event called with name: $name and location: $location")
    }
}

