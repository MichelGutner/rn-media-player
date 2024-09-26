package com.rnvideoplayer.ui.components

import android.view.View
import android.widget.PopupMenu
import androidx.core.content.ContextCompat
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R
import com.rnvideoplayer.helpers.ReadableMapManager
import com.rnvideoplayer.helpers.SharedStore

class PopUpMenu(
  data: MutableSet<String>,
  private val context: ThemedReactContext,
  view: View,
  callback: (String, Any) -> Unit
) {
  private val dialog = CustomBottomDialog(context)
  private var contentDialog = CustomContentDialog(context, dialog)
  private val popup = PopupMenu(context, view)
  private var selectedItem: String? = null
  private var companionStorage = SharedStore.getInstance()

  init {
    data.forEach { menuItemTitle ->
      val item = popup.menu.add(menuItemTitle)
      item.icon = ContextCompat.getDrawable(context, R.drawable.arrow_forward)
      item.setOnMenuItemClickListener { menuItem ->
        val option = ReadableMapManager.getInstance().getReadableMapProps(menuItem.title.toString())
        selectedItem = option.getString("initialItemSelected") ?: ""
        if (companionStorage.getString(menuItemTitle) == null) {
          companionStorage.putString(menuItemTitle, selectedItem!!)
        }

        contentDialog.showOptionsDialog(option.getArray("data"), companionStorage.getString(menuItemTitle)) { name, value ->
          callback(menuItemTitle, value)
          companionStorage.putString(menuItemTitle, name)
          view.requestLayout()
          view.invalidate()
        }
        true
      }
    }
  }

  fun show() {
    popup.inflate(R.menu.popup_menu)
    popup.gravity = 5
    popup.show()
  }
}
