package com.rnvideoplayer.components

import android.annotation.SuppressLint
import android.graphics.Color
import android.view.View
import android.widget.ProgressBar
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R

@SuppressLint("ViewConstructor")
class CustomLoading(context: ThemedReactContext, view: View, attrs: ReadableArray? = null): ProgressBar(context) {
    private val loading = view.findViewById<ProgressBar>(R.id.progress_bar)

  init {
    loading.indeterminateDrawable.setColorFilter(Color.BLUE, android.graphics.PorterDuff.Mode.SRC_IN)
  }

  fun show() {
    loading.visibility = View.VISIBLE
  }

  fun hide() {
    loading.visibility = View.INVISIBLE
  }
}
