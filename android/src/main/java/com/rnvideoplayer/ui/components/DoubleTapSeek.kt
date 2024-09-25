package com.rnvideoplayer.ui.components

import android.annotation.SuppressLint
import android.util.TypedValue
import android.view.GestureDetector
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.RelativeLayout
import android.widget.TextView
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R
import com.rnvideoplayer.fadeIn
import com.rnvideoplayer.fadeOut
import com.rnvideoplayer.helpers.SharedStore
import com.rnvideoplayer.helpers.SharedStoreKey
import com.rnvideoplayer.helpers.TimeoutWork
import com.rnvideoplayer.utilities.ColorUtils
import com.rnvideoplayer.utils.scaleView

@SuppressLint("SetTextI18n", "ViewConstructor")
class DoubleTapSeek(
  private val context: ThemedReactContext,
  private val isForward: Boolean
) : FrameLayout(context) {
  private val doubleTapView: LinearLayout = createDoubleTapView()
  val doubleTapBackground: RelativeLayout = createDoubleTapEffectBackground()
  val doubleTapText: TextView = createDoubleTapText()

  private var tappedQuantity: Int = 1
  private val timeoutWork = TimeoutWork()
  private var suffixLabel: String = "seconds"
  private var doubleTapValue: Long = 15000

  init {
    setupLayout()
    doubleTapView.addView(doubleTapBackground)
    doubleTapBackground.addView(doubleTapText)
    addView(doubleTapView)
  }

  private fun setupLayout() {
    doubleTapView.viewTreeObserver.addOnGlobalLayoutListener {
      suffixLabel = SharedStore.getInstance().getString(SharedStoreKey.SUFFIX_LABEL).toString()
      SharedStore.getInstance().getLong(SharedStoreKey.DOUBLE_TAP_VALUE)?.also {
        doubleTapValue = it
      }
      scaleView(isForward, doubleTapView)

      val layoutParams = doubleTapText.layoutParams as MarginLayoutParams
      if (isForward) {
        layoutParams.marginStart = context.resources.displayMetrics.widthPixels / 5
      } else {
        layoutParams.marginEnd = context.resources.displayMetrics.widthPixels / 5
      }
      doubleTapText.layoutParams = layoutParams

      doubleTapView.requestLayout()
      doubleTapBackground.requestLayout()
      doubleTapText.requestLayout()
    }
  }

  @SuppressLint("ClickableViewAccessibility")
  fun tap(
    onSingleTap: (doubleTapValue: Long) -> Unit,
    onDoubleTap: (doubleTapValue: Long) -> Unit
  ) {
    doubleTapView.setOnTouchListener(object : OnTouchListener {
      val gestureDetector =
        GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
          override fun onDoubleTap(e: MotionEvent): Boolean {
            tappedQuantity++
            timeoutWork.cancelTimer()
            doubleTapBackground.fadeIn(100)
            timeoutWork.createTask {
              doubleTapBackground.fadeOut(100, completion = {
                tappedQuantity = 0
              })
            }
            onDoubleTap(doubleTapValue * 1000)
            doubleTapText.text = "${doubleTapValue.times(tappedQuantity)} $suffixLabel"

            return super.onDoubleTap(e)
          }

          override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
            timeoutWork.cancelTimer()
            if (doubleTapBackground.visibility == VISIBLE) {
              tappedQuantity++
              timeoutWork.createTask {
                doubleTapBackground.fadeOut(100, completion = {
                  tappedQuantity = 0
                })
              }
            }
            onSingleTap(doubleTapValue * 1000)
            doubleTapText.text = "${doubleTapValue.times(tappedQuantity)} $suffixLabel"
            return super.onSingleTapConfirmed(e)
          }
        })

      override fun onTouch(v: View?, event: MotionEvent): Boolean {
        gestureDetector.onTouchEvent(event)
        return false
      }
    })
  }

  private fun createDoubleTapView(): LinearLayout {
    val doubleTap = LinearLayout(context).apply {
      layoutParams = LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.MATCH_PARENT
      ).apply {
        setBackgroundResource(R.drawable.rounded_background_double_tap)
        isClickable = true
        isFocusable = true
        visibility = VISIBLE
      }
    }
    return doubleTap
  }

  private fun createDoubleTapEffectBackground(): RelativeLayout {
    val effectBackground = RelativeLayout(context).apply {
      layoutParams = LayoutParams(
        RelativeLayout.LayoutParams.MATCH_PARENT,
        RelativeLayout.LayoutParams.MATCH_PARENT
      ).apply {
        val typedValue = TypedValue()
        context.theme.resolveAttribute(
          android.R.attr.selectableItemBackgroundBorderless,
          typedValue,
          true
        )
        setBackgroundResource(typedValue.resourceId)
        gravity = Gravity.CENTER
        visibility = View.INVISIBLE
      }
    }
    return effectBackground
  }

  private fun createDoubleTapText(): TextView {
    val textView = TextView(context).apply {
      layoutParams = RelativeLayout.LayoutParams(
        RelativeLayout.LayoutParams.MATCH_PARENT,
        RelativeLayout.LayoutParams.WRAP_CONTENT
      ).apply {
        addRule(RelativeLayout.CENTER_VERTICAL)
        if (isForward) {
          marginStart = context.resources.displayMetrics.widthPixels / 5
        } else {
          marginEnd = context.resources.displayMetrics.widthPixels / 5
        }
      }
      gravity = if (isForward) Gravity.START else Gravity.END
      setTextColor(ColorUtils.white)
      setTextSize(TypedValue.COMPLEX_UNIT_PX, resources.getDimension(R.dimen.double_tap_text_size))
    }
    return textView
  }


}
