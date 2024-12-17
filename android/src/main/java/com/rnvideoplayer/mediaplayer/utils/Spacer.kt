package com.rnvideoplayer.mediaplayer.utils

import android.content.Context
import android.view.View
import android.widget.LinearLayout

fun spacer (context: Context) : View {
  return View(context).apply {
    layoutParams = LinearLayout.LayoutParams(0, 0).apply {
      weight = 1f
    }
  }
}
