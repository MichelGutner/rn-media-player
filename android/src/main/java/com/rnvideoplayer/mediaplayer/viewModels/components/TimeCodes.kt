package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.view.marginLeft
import androidx.core.view.setPadding
import com.rnvideoplayer.R
import com.rnvideoplayer.utils.layoutParamsWithGravityCenter
import com.rnvideoplayer.utils.TimeFormat

class TimeCodes(context: Context) : LinearLayout(context) {
  private var time = TimeFormat()
  val position = createTextView(context)
  val duration = createTextView(context)

//  private val linearLayout = timesCodesView(context)

//  init {
//    addView(linearLayout)
//  }

  fun setPosition(time: Long) {
    position.text = this.time.format(time)
  }

  fun setDuration(value: Long) {
    duration.text = time.format(value)
  }

  private fun createTextView(context: Context): TextView {
    return TextView(context).apply {
      setTextColor(Color.WHITE)
      layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
        gravity = Gravity.CENTER
      }
      text = context.getString(R.string.time_codes_start_value)
      textSize = 12f
    }
  }

//  private fun timesCodesView(context: Context): LinearLayout {
//    return LinearLayout(context).apply {
//      orientation = HORIZONTAL
//      setPadding(12,0,12,0)
//      layoutParams = LayoutParams(
//        LayoutParams.MATCH_PARENT,
//        LayoutParams.WRAP_CONTENT
//      )
//
//      addView(position.apply {
//        layoutParams = LayoutParams(
//          LayoutParams.WRAP_CONTENT,
//          LayoutParams.WRAP_CONTENT
//        )
//      })
//
////      addView(View(context).apply {
////        layoutParams = LayoutParams(0, 0).apply {
////          weight = 1f
////        }
////      })
//
//      addView(duration.apply {
//        layoutParams = LayoutParams(
//          LayoutParams.WRAP_CONTENT,
//          LayoutParams.WRAP_CONTENT
//        )
//      })
//    }
//  }
}
