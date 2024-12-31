package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import com.rnvideoplayer.R
import com.rnvideoplayer.utils.layoutParamsWithGravityCenter
import com.rnvideoplayer.utils.TimeCodesFormat

class TimeCodes(context: Context) : LinearLayout(context) {
  private var helper = TimeCodesFormat()
  private val position = createTextView(context)
  private val duration = createTextView(context)

  private val linearLayout = timesCodesView(context)

  init {
    addView(linearLayout)
  }

  fun setPosition(time: Long) {
    position.text = helper.format(time)
  }

  fun setDuration(time: Long) {
    duration.text = helper.format(time)
  }

  private fun createTextView(context: Context): TextView {
    return TextView(context).apply {
      setTextColor(Color.WHITE)
      layoutParams = layoutParamsWithGravityCenter(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
      text = context.getString(R.string.time_codes_start_value)
    }
  }

  private fun timesCodesView(context: Context): LinearLayout {
    return LinearLayout(context).apply {
      orientation = HORIZONTAL
      setPadding(12,0,12,0)
      layoutParams = LayoutParams(
        LayoutParams.MATCH_PARENT,
        LayoutParams.WRAP_CONTENT
      )

      addView(position.apply {
        layoutParams = LayoutParams(
          LayoutParams.WRAP_CONTENT,
          LayoutParams.WRAP_CONTENT
        )
      })

      addView(View(context).apply {
        layoutParams = LayoutParams(0, 0).apply {
          weight = 1f
        }
      })

      addView(duration.apply {
        layoutParams = LayoutParams(
          LayoutParams.WRAP_CONTENT,
          LayoutParams.WRAP_CONTENT
        )
      })
    }
  }
}
