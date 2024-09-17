package com.rnvideoplayer.components

import android.annotation.SuppressLint
import android.view.LayoutInflater
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.media3.ui.PlayerView
import com.facebook.react.bridge.ReadableNativeArray
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R

@SuppressLint("ResourceType")
class CustomContentDialog(private val context: ThemedReactContext, private val dialog: CustomBottomDialog) {


  data class OptionItem(val name: String, val value: Any)

  fun showOptionsDialog(optionsData: ReadableNativeArray, selectedOption: String?, callback: (String, Any) -> Unit) {
    val dialogView = LayoutInflater.from(context).inflate(R.layout.options_dialog, null)

    var optionItems: List<OptionItem>  = mutableListOf()
    for (i in optionsData.toArrayList()) {
      val data = i as? Map<*, *>
      val name = data?.get("name") as? String
      val value = data?.get("value")
      if (name != null && value != null) {
        optionItems += OptionItem(name, value)
      }
    }

    val optionsLayout: LinearLayout = dialogView.findViewById(R.id.qualityOptionsLayout)

    for (option in optionItems) {

      val optionView = LayoutInflater.from(context).inflate(R.layout.option_item, null)
      val optionNameTextView: TextView = optionView.findViewById(R.id.qualityNameTextView)
      val optionCheckImageView: ImageView = optionView.findViewById(R.id.checkImage)

      optionNameTextView.text = option.name
      optionCheckImageView.visibility = if (option.name == selectedOption) PlayerView.VISIBLE else PlayerView.VISIBLE

      optionView.setOnClickListener {
        if (selectedOption == option.name) {
          return@setOnClickListener
        } else {
          it.postDelayed({
            dialog.dismiss()
          }, 300)
        }
        callback(option.name, option.value)
      }

      optionsLayout.addView(optionView)
    }

    dialog.setContentView(dialogView)
    dialog.show()
  }
}
