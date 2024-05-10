package com.rnvideoplayer

import android.app.Activity
import android.app.AlertDialog

class SettingsDialog internal constructor(private val activity: Activity) {
  private var dialog: AlertDialog? = null

  fun showDialog() {
    val builder = AlertDialog.Builder(activity)

    val inflater = activity.layoutInflater
    builder.setView(inflater.inflate(R.layout.custom_dialog, null))
    builder.setCancelable(true)


    dialog = builder.create()
    dialog!!.show()
  }

  fun dismissDialog() {
    dialog!!.dismiss()
  }
}
