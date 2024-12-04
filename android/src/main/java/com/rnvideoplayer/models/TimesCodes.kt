package com.rnvideoplayer.models

import android.content.Context
import android.widget.LinearLayout
import android.widget.TextView
import com.rnvideoplayer.R
import com.rnvideoplayer.helpers.RNVideoHelpers
import com.rnvideoplayer.utilities.ColorUtils
import com.rnvideoplayer.utilities.layoutParamsCenter

class TimesCodes(context: Context) : LinearLayout(context) {
  private var helper = RNVideoHelpers()
  private val timeCodes = createTextView(context)

  init {
    visibility = INVISIBLE
    addView(timeCodes)
  }

  fun createWithFormattedTime(time: Long) {
    timeCodes.text = helper.createTimeCodesFormatted(time)
  }

  private fun createTextView(context: Context): TextView {
    return TextView(context).apply {
      setTextColor(ColorUtils.white)
      layoutParams = layoutParamsCenter(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
      text = context.getString(R.string.time_codes_start_value)
    }
  }
}
