package com.rnvideoplayer.mediaplayer.viewModels.components

import android.app.Activity
import android.content.Context
import android.os.Build
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.widget.PopupMenu
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.ReadableMap
import com.rnvideoplayer.R
import com.rnvideoplayer.mediaplayer.models.ReactConfigAdapter

private var selectedItemMap = mutableMapOf<String, String>()

@Suppress("UNCHECKED_CAST")
class PopUpMenu(
    private var context: Context,
    view: View,
    callback: (String, Any) -> Unit
) {
  private val window = (view.context as? Activity)?.window
  private val reactConfigAdapter = ReactConfigAdapter.getInstance()
  private val popup = PopupMenu(context, view)

  init {

    val menuItems = reactConfigAdapter.get(ReactConfigAdapter.Key.MENU_ITEMS) as MutableSet<String>
    menuItems.forEach { menuItemTitle ->
      val optionReadableMap = reactConfigAdapter.get(menuItemTitle) as ReadableMap
      val options = optionReadableMap.getArray("data")

      if (selectedItemMap[menuItemTitle] == null) {
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
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      window?.setDecorFitsSystemWindows(false)
      window?.insetsController?.let { controller ->
        controller.hide(WindowInsets.Type.systemBars())
        controller.systemBarsBehavior =
          WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
      }
    } else {
      @Suppress("DEPRECATION")
      window?.decorView?.systemUiVisibility = (
        View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
          View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
          View.SYSTEM_UI_FLAG_FULLSCREEN or
          View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
          View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
          View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
    }
    popup.inflate(R.menu.popup_menu)
    popup.gravity = 1
    popup.show()
  }
}
