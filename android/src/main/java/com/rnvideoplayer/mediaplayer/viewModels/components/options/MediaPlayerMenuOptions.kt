package com.rnvideoplayer.mediaplayer.viewModels.components.options

import android.annotation.SuppressLint
import android.content.Context
import android.view.LayoutInflater
import android.view.View.INVISIBLE
import android.view.View.VISIBLE
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.facebook.react.bridge.ReadableMap
import com.rnvideoplayer.R
import com.rnvideoplayer.mediaplayer.logger.Debug
import com.rnvideoplayer.mediaplayer.models.RCTConfigs

enum class OptionsDialogType {
  QUALITIES,
  SPEEDS,
  CAPTIONS
}

interface MediaPlayerMenuOptionsListener {
  fun onSelected(optionType: OptionsDialogType, title: String, value: Any)
}

private var selectedOptionByType = mutableMapOf<String, String>()

@SuppressLint("ResourceType")
class MediaPlayerMenuOptions(
  private val context: Context,
  private val dialog: CustomDialog
) {

  private var listener: MediaPlayerMenuOptionsListener? = null
  fun setListener(listener: MediaPlayerMenuOptionsListener) {
    this.listener = listener
    Debug.log("MediaPlayerMenuOptionsListener has been initialized with success listener: $listener")
  }

  @SuppressLint("InflateParams", "MissingInflatedId")
  fun showOptionsDialog(
    optionsData: List<String>,
  ) {
    val dialogView = LayoutInflater.from(context).inflate(R.layout.options_dialog, null)
    val optionsLayout: LinearLayout = dialogView.findViewById(R.id.optionsItem)
    val reactConfigAdapter = RCTConfigs.getInstance()


    var optionItems: MutableList<MediaPlayerMenuOptionsDataClass> = mutableListOf()

    for (option in optionsData) {
      val optionReadableMap = reactConfigAdapter.get(option) as? ReadableMap
      val title = optionReadableMap?.getString("title")
      val isDisabled = optionReadableMap?.getBoolean("disabled") ?: false
      val optionsList = optionReadableMap?.getArray("options")
      val initialOptionSelected = optionReadableMap?.getString("initialOptionSelected") ?: ""

      if (selectedOptionByType[option.lowercase()] == null && initialOptionSelected.isNotBlank()) {
        selectedOptionByType[option.lowercase()] = initialOptionSelected
      }

      if (!isDisabled && title != null) {
        optionItems.add(
          MediaPlayerMenuOptionsDataClass(
            title,
            optionsList,
            option.lowercase(),
            selectedOptionByType[option]
          )
        )
      }
    }

    optionItems = optionItems.sortedBy {
      when (it.parentName) {
        "qualities" -> 0
        "speeds" -> 1
        "captions" -> 2
        else -> 3
      }
    }.toMutableList()

    for (option in optionItems) {
      val optionView = LayoutInflater.from(context).inflate(R.layout.option_item, null)
      val optionNameTextView: TextView = optionView.findViewById(R.id.optionItemText)
      val selectedItemTextView: TextView = optionView.findViewById(R.id.selectedItemText)
      val menuItemImageView: ImageView = optionView.findViewById(R.id.menuItemImage)

      when (option.parentName) {
        "qualities" -> {
          menuItemImageView.setImageResource(R.drawable.baseline_equalizer_24)
        }

        "speeds" -> {
          menuItemImageView.setImageResource(R.drawable.baseline_slow_motion_video_24)
        }

        "captions" -> {
          menuItemImageView.setImageResource(R.drawable.outline_captions_24)
        }
      }
      optionNameTextView.text = option.name
      selectedItemTextView.text = option.optionSelected

      optionView.setOnClickListener {
        it.postDelayed({
          dialog.dismiss()
          showOptions(option)
        }, 300)
      }

      optionsLayout.addView(optionView)
    }

    dialog.setContentView(dialogView)
    dialog.show()
  }

  @SuppressLint("InflateParams", "MissingInflatedId")
  fun showOptions(
    optionData: MediaPlayerMenuOptionsDataClass,
  ) {
    val optionItems: MutableList<OptionItem> = mutableListOf()
    val dialogView = LayoutInflater.from(context).inflate(R.layout.options_dialog, null)
    val optionsLayout: LinearLayout = dialogView.findViewById(R.id.optionsItem)

    if (optionData.value != null) {
      for (i in optionData.value.toArrayList()) {
        val data = i as? Map<*, *>
        val name = data?.get("name") as? String
        val value = data?.get("value")
        if (name != null && value != null) {
          optionItems += OptionItem(name, value)
        }
      }
    }

    for (option in optionItems) {
      val optionView = LayoutInflater.from(context).inflate(R.layout.option_item, null)
      val optionNameTextView: TextView = optionView.findViewById(R.id.optionItemText)
      val menuItemImage: ImageView = optionView.findViewById(R.id.menuItemImage)
      val optionRightIcon: ImageView = optionView.findViewById(R.id.optionRightIcon)

      optionRightIcon.visibility = INVISIBLE
      optionNameTextView.text = option.name
      menuItemImage.setImageResource(R.drawable.baseline_check)

      menuItemImage.visibility =
        if (option.name == optionData.optionSelected) VISIBLE else INVISIBLE

      optionView.setOnClickListener {
        if (selectedOptionByType[optionData.parentName] == option.name) {
          return@setOnClickListener
        } else {
          selectedOptionByType[optionData.parentName] = option.name
        }

        it.postDelayed({
          dialog.dismiss()
          listener?.onSelected(
            OptionsDialogType.valueOf(optionData.parentName.uppercase()),
            option.name,
            option.value
          )
        }, 500)
      }

      optionsLayout.addView(optionView)
    }

    dialog.setContentView(dialogView)
    dialog.show()
  }
}
