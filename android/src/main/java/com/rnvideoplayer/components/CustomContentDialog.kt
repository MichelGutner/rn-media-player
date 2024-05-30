package com.rnvideoplayer.components

import android.annotation.SuppressLint
import android.view.LayoutInflater
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.media3.ui.PlayerView
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R
import com.rnvideoplayer.interfaces.enabled
import com.rnvideoplayer.interfaces.name
import com.rnvideoplayer.interfaces.value

@SuppressLint("ResourceType")
class CustomContentDialog(private val context: ThemedReactContext, private val dialog: CustomBottomDialog) {


  data class OptionItem(val name: String, val value: String, val enabled: Boolean)

  fun showOptionsDialog(optionsData: ReadableArray?, selectedOption: String?, callback: (String, String) -> Unit) {
    val dialogView = LayoutInflater.from(context).inflate(R.layout.options_dialog, null)


    val optionItems = mutableListOf<OptionItem>()
    for (i in 0 until optionsData?.size()!!) {
      val item = optionsData.getMap(i)
      if (item.enabled) {
        optionItems.add(OptionItem(item.name, item.value, item.enabled))
      }
    }

    val optionsLayout: LinearLayout = dialogView.findViewById(R.id.qualityOptionsLayout)

    for (option in optionItems) {
      val optionView = LayoutInflater.from(context).inflate(R.layout.option_item, null)
      val optionNameTextView: TextView = optionView.findViewById(R.id.qualityNameTextView)
      val optionCheckImageView: ImageView = optionView.findViewById(R.id.checkImage)

      optionNameTextView.text = option.name
      optionCheckImageView.visibility = if (option.name == selectedOption) PlayerView.VISIBLE else PlayerView.GONE

      optionView.setOnClickListener {
        if (selectedOption == option.name) {
          return@setOnClickListener
        } else {
          it.postDelayed({
            dialog.dismiss()
          }, 300)
        }
        // Handle option item click
        // playVideo(option.value)
        callback(option.name, option.value)
      }

      optionsLayout.addView(optionView)
    }

    dialog.setContentView(dialogView)
    dialog.show()
  }
}
