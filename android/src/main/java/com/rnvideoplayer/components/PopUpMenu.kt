package com.rnvideoplayer.components

import android.view.View
import android.widget.PopupMenu
import androidx.core.content.ContextCompat
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R
import com.rnvideoplayer.helpers.ReadableMapManager

class PopUpMenu(data: MutableSet<String>, private val context: ThemedReactContext, view: View, callback: (String, Any) -> Unit) {
  private val dialog = CustomBottomDialog(context)
  private var contentDialog = CustomContentDialog(context, dialog)
  val popup = PopupMenu(context, view)

  init {
    data.forEach { menuItemTitle ->
      val item = popup.menu.add(menuItemTitle)
      item.icon = ContextCompat.getDrawable(context, R.drawable.arrow_forward)
      item.setOnMenuItemClickListener { menuItem ->
        val option = ReadableMapManager.getInstance().getReadableMapProps(menuItem.title.toString())
        contentDialog.showOptionsDialog(option, "") { _, value ->
          callback(menuItemTitle, value)
        }
        true
      }
    }
  }

  fun show() {
    popup.inflate(R.menu.popup_menu)
    popup.gravity.also { popup.gravity = 5 }
    popup.show()
  }
}
