package com.rnvideoplayer.ui.components

import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.widget.PopupMenu
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.ReadableMap
import com.rnvideoplayer.R
import com.rnvideoplayer.mediaplayer.models.ReactConfig

private var selectedItemMap = mutableMapOf<String, String>()

class PopUpMenu(
  private var context: Context,
  view: View,
  callback: (String, Any) -> Unit
) {
  private val reactConfig = ReactConfig.getInstance()
  private val popup = PopupMenu(context, view)

  init {

    val menuItems = reactConfig.get(ReactConfig.Key.MENU_ITEMS) as MutableSet<String>
    menuItems.forEach { menuItemTitle ->
      val optionReadableMap = reactConfig.get(menuItemTitle) as ReadableMap
      val options = optionReadableMap.getArray("data")

      if (selectedItemMap[menuItemTitle] == null) {
        println("selected item: ${selectedItemMap[menuItemTitle]}")
        selectedItemMap[menuItemTitle] = optionReadableMap.getString("initialItemSelected") ?: ""
      }

      val item = popup.menu.addSubMenu(menuItemTitle)

      options?.toArrayList()?.forEach { it ->
        val option = it as? Map<*, *>
        val name = option?.get("name")
        val value = option?.get("value");
        val subItem = item.add(name.toString())
        if (selectedItemMap[menuItemTitle] == subItem.title) {
          subItem.setIcon(ContextCompat.getDrawable(context, R.drawable.baseline_check))
        }
        subItem.setOnMenuItemClickListener { subMenuItem ->
          if (value != null) {
            callback(menuItemTitle, value)
            selectedItemMap[menuItemTitle] = subMenuItem.title.toString()
          }
          true
        }
      }
    }
  }

  fun show() {
    popup.inflate(R.menu.popup_menu)
    popup.gravity = 1
    popup.show()
  }
}
