package com.rnvideoplayer.mediaplayer.viewModels.components.options

import android.annotation.SuppressLint
import android.content.Context
import android.view.LayoutInflater
import android.view.View.INVISIBLE
import android.view.View.VISIBLE
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.media3.common.Format
import androidx.media3.common.util.UnstableApi
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.rnvideoplayer.R
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

@UnstableApi
@SuppressLint("ResourceType")
class MediaPlayerMenuOptions(
  private val context: Context,
  private val dialog: CustomDialog,
  private val closedCaptions: MutableList<Format>
) {
  private var listener: MediaPlayerMenuOptionsListener? = null

  companion object {
    val TAG: String = MediaPlayerMenuOptions::class.java.simpleName
  }

  fun setListener(listener: MediaPlayerMenuOptionsListener) {
    this.listener = listener
  }

  @SuppressLint("InflateParams", "MissingInflatedId")
  fun showOptions(
    optionsData: List<String>,
  ) {
    val dialogView = LayoutInflater.from(context).inflate(R.layout.options_dialog, null)
    val optionsLayout: LinearLayout = dialogView.findViewById(R.id.optionsItem)
    val reactConfigAdapter = RCTConfigs.getInstance()

    var optionItems: MutableList<MediaPlayerMenuOptionsDataClass> = mutableListOf()
    val map: WritableArray = Arguments.createArray()

    for (option in optionsData) {
      val optionReadableMap = reactConfigAdapter.get(option) as? ReadableMap
      val title = optionReadableMap?.getString("title")
      val disabledCaptionName = optionReadableMap?.getString("disabledCaptionName")
      val isDisabled = optionReadableMap?.getBoolean("disabled") ?: false
      val optionsList = optionReadableMap?.getArray("options")
      val initialOptionSelected = optionReadableMap?.getString("initialOptionSelected") ?: ""

      if (selectedOptionByType[option.lowercase()] == null && initialOptionSelected.isNotBlank()) {
        selectedOptionByType[option.lowercase()] = initialOptionSelected
      }

      if (!isDisabled && title != null) {
        if (option != "captions") {
          optionItems.add(
            MediaPlayerMenuOptionsDataClass(
              title,
              optionsList,
              option.lowercase(),
              selectedOptionByType[option]
            )
          )
        } else {
          map.pushMap(
            Arguments.createMap().apply {
              putString("name", disabledCaptionName)
              putString("value", "")
            }
          )
          closedCaptions.forEach { track ->
            val mutableSet: WritableMap = Arguments.createMap()
            mutableSet.putString("name", track.label)
            mutableSet.putString("value", track.language)
            map.pushMap(mutableSet)
          }

          optionItems.add(
            MediaPlayerMenuOptionsDataClass(
              title,
              map,
              option.lowercase(),
              selectedOptionByType[option] ?: disabledCaptionName
            )
          )
        }
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
          showSubOptions(option)
        }, 400)
          dialog.dismiss()
      }

      optionsLayout.addView(optionView)
    }

    dialog.setContentView(dialogView)
    dialog.show()
  }

  @SuppressLint("InflateParams", "MissingInflatedId")
  fun showSubOptions(
    subOptions: MediaPlayerMenuOptionsDataClass,
  ) {
    val optionItems: MutableList<OptionItem> = mutableListOf()
    val dialogView = LayoutInflater.from(context).inflate(R.layout.options_dialog, null)
    val optionsLayout: LinearLayout = dialogView.findViewById(R.id.optionsItem)

      for (i in subOptions.value?.toArrayList()!!) {
        val data = i as? Map<*, *>
        val name = data?.get("name") as? String
        val value = data?.get("value")
        if (name != null && value != null) {
          optionItems += OptionItem(name, value)
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
        if (option.name == subOptions.optionSelected) VISIBLE else INVISIBLE

      optionView.setOnClickListener {
        if (selectedOptionByType[subOptions.parentName] == option.name) {
          return@setOnClickListener
        } else {
          selectedOptionByType[subOptions.parentName] = option.name
        }

        it.postDelayed({
          dialog.dismiss()
          listener?.onSelected(
            OptionsDialogType.valueOf(subOptions.parentName.uppercase()),
            option.name,
            option.value
          )
        }, 300)
      }

      optionsLayout.addView(optionView)
    }

    dialog.setContentView(dialogView)
    dialog.show()
  }
}
