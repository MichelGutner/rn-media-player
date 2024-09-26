package com.rnvideoplayer.components

import android.annotation.SuppressLint
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.view.View.VISIBLE
import android.view.ViewGroup
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
import com.rnvideoplayer.utils.scaleView

@SuppressLint("SetTextI18n")
class CustomDoubleTapSeek(
  private val context: ThemedReactContext,
  private val view: View,
  private val isForward: Boolean
) {
  private val doubleTapViewId = if (!isForward) R.id.left_double_tap_view else R.id.right_double_tap_view
  private val doubleTapEffectId = if (!isForward) R.id.left_double_tap_background_effect else R.id.right_double_tap_background_effect
  private val doubleTapTextId = if (!isForward) R.id.left_double_tap_text else R.id.right_double_tap_text

  private val doubleTapView: LinearLayout = view.findViewById(doubleTapViewId)
  val doubleTapBackground: RelativeLayout = view.findViewById(doubleTapEffectId)
  val doubleTapText: TextView = view.findViewById(doubleTapTextId)
  private var tappedQuantity: Int = 1
  private val timeoutWork = TimeoutWork()
  private var suffixLabel: String = "seconds"
  private var doubleTapValue: Long = 15000

  init {
    setupLayout()
  }

  private fun setupLayout() {
    doubleTapView.viewTreeObserver.addOnGlobalLayoutListener {
      suffixLabel = SharedStore.getInstance().getString(SharedStoreKey.SUFFIX_LABEL).toString()
      SharedStore.getInstance().getLong(SharedStoreKey.DOUBLE_TAP_VALUE)?.also {
        doubleTapValue = it
      }
      doubleTapText.text = "${doubleTapValue.times(tappedQuantity)} $suffixLabel"
      scaleView(isForward, doubleTapView)
      val layoutParams = doubleTapText.layoutParams as ViewGroup.MarginLayoutParams
      if (isForward) {
        layoutParams.marginStart = view.width / 5
      } else {
        layoutParams.marginEnd = view.width / 5
      }
      doubleTapText.layoutParams = layoutParams
      doubleTapView.requestLayout()
      doubleTapBackground.requestLayout()
      doubleTapText.requestLayout()
    }
  }

  @SuppressLint("ClickableViewAccessibility")
  fun tap(onSingleTap: (doubleTapValue: Long) -> Unit, onDoubleTap: (doubleTapValue: Long) -> Unit) {
    doubleTapView.setOnTouchListener(object : View.OnTouchListener {
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
            onDoubleTap(doubleTapValue)
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
            onSingleTap(doubleTapValue)
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
}
