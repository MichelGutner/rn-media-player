package com.rnvideoplayer.mediaplayer.viewModels.components

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.util.TypedValue
import android.view.Gravity
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.view.isVisible
import com.rnvideoplayer.R
import com.rnvideoplayer.fadeIn
import com.rnvideoplayer.fadeOut
import com.rnvideoplayer.helpers.TimeoutWork
import com.rnvideoplayer.utils.scaleView

@SuppressLint("SetTextI18n", "ViewConstructor")
class DoubleTapSeek(
  private val context: Context,
  private val isForward: Boolean
) : LinearLayout(context) {
  private val timeoutWork = TimeoutWork()
  private val text: TextView = text()
  private var tappedQuantity: Int = 1
  private val contentView = contentView()
  var isVisible: Boolean = false

  var suffixLabel: String = "seconds"
  var tapValue: Int = 15

  init {
    setupLayout()
  }

  fun clickListener(onSingleTap: () -> Unit) {
    this.setOnClickListener {
      onSingleTap()

      timeoutWork.cancelTimer()
      tappedQuantity++

      updateDoubleTapText(tappedQuantity)
      hide()
    }
  }

  fun hide() {
    timeoutWork.createTask(700){
      fadeOut(100) {
        tappedQuantity = 0
      }
    }
  }

  fun show() {
    fadeIn {
      isVisible = true
    }
    updateDoubleTapText(1)
  }

  private fun updateDoubleTapText(quantity: Int) {
    text.text = "${tapValue * quantity} $suffixLabel"
  }

  private fun setupLayout() {
    gravity = if (isForward) Gravity.START else Gravity.END
      layoutParams = LayoutParams(
        LayoutParams.MATCH_PARENT,
        LayoutParams.MATCH_PARENT
      ).apply {
        isClickable = true
        isFocusable = true
        setBackgroundResource(R.drawable.rounded_background_double_tap)
        visibility = INVISIBLE
      }

    contentView.addView(animationIcon())
    contentView.addView(text)
    addView(contentView)

    viewTreeObserver.addOnGlobalLayoutListener {
      post {
        contentView.layoutParams = setupLayoutParamsContentView()
        scaleView(isForward, this)
        requestLayout()
      }
    }
  }

  private fun contentView(): LinearLayout {
    val layout = LinearLayout(context).apply {
      layoutParams = setupLayoutParamsContentView()
      orientation = VERTICAL
    }
    return layout
  }

  private fun setupLayoutParamsContentView(): LayoutParams {
    return LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
      gravity = Gravity.CENTER
      if (isForward) {
        marginStart = (context.resources.displayMetrics.widthPixels * 0.1).toInt()
      } else {
        marginEnd = (context.resources.displayMetrics.widthPixels * 0.1).toInt()
      }
    }
  }

  private fun text(): TextView {
    val minWidth = (context.resources.displayMetrics.widthPixels * 0.2).toInt()
    val textView = TextView(context).apply {
      layoutParams = LayoutParams(
        minWidth,
        LayoutParams.MATCH_PARENT
      )
      gravity = Gravity.CENTER
      setTextColor(Color.WHITE)
      setTextSize(TypedValue.COMPLEX_UNIT_PX, resources.getDimension(R.dimen.double_tap_text_size))
    }
    return textView
  }

  private fun animationIcon(): LinearLayout {
    val container = LinearLayout(context).apply {
      layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT).apply {
      }
      gravity = Gravity.CENTER
      orientation = HORIZONTAL
      visibility = if (isVisible) VISIBLE else INVISIBLE
    }

    val icons = mutableSetOf<ImageView>()

    for (i in 0 until 3) {
      val icon = ImageView(context).apply {
        layoutParams = LayoutParams(40, 40).apply {
          gravity = Gravity.CENTER
          marginEnd = if (i != 2) 10 else 0
          rotation = if (!isForward) 180f else 0f
        }
        alpha = 0.3f
        setImageResource(R.drawable.play_vector)
      }

      icons.add(icon)
      container.addView(icon)
    }

    fun animateIcons (index: Int) {
      if (index < 0 || index >= icons.size) {
        postDelayed({ animateIcons(if (isForward)0 else icons.size - 1)}, 0)
        return
      }

      val unselectedIcons = icons.filterIndexed { i, _ -> i != index }
      unselectedIcons.forEach { icon ->
        icon.alpha = 0.3f
      }

      val icon = icons.elementAt(index)

      icon.alpha = 1f
      postDelayed({
        animateIcons( if (isForward) index + 1 else index - 1)
      }, 300)
    }

    post { animateIcons(0) }
    return container
  }
}
