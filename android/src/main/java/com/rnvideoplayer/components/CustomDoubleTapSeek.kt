package com.rnvideoplayer.components

import android.annotation.SuppressLint
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.RelativeLayout
import android.widget.TextView
import androidx.media3.ui.PlayerView
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R
import com.rnvideoplayer.helpers.TimeoutWork
import com.rnvideoplayer.utils.fadeIn
import com.rnvideoplayer.utils.fadeOut
import com.rnvideoplayer.utils.scaleView

@SuppressLint("SetTextI18n")
class CustomDoubleTapSeek(
  private val context: ThemedReactContext,
  view: View,
  isForward: Boolean
) {
  private val doubleTapViewId = if (!isForward) R.id.double_tap_view else R.id.double_tap_right_view
  private val doubleTapEffectId = if (!isForward) R.id.double_tap else R.id.double_tap_2
  private val doubleTapTextId = if (!isForward) R.id.double_tap_text else R.id.double_tap_text_2

  private val doubleTapView: LinearLayout = view.findViewById(doubleTapViewId)
  val effect: RelativeLayout = view.findViewById(doubleTapEffectId)
  val doubleTapText: TextView = view.findViewById(doubleTapTextId)
  private var tappedQuantity: Int = 0
  private val timeoutWork = TimeoutWork()

  init {
    setupLayout(view, isForward)
  }

  private fun setupLayout(view: View, isForward: Boolean) {
    doubleTapView.viewTreeObserver.addOnGlobalLayoutListener {
      scaleView(isForward, doubleTapView)
      val layoutParams = doubleTapText.layoutParams as ViewGroup.MarginLayoutParams
      if (isForward) {
        layoutParams.marginStart = view.width / 5
      } else {
        layoutParams.marginEnd = view.width / 5
      }
      doubleTapText.layoutParams = layoutParams
      doubleTapView.requestLayout()
    }
  }

  @SuppressLint("ClickableViewAccessibility")
  fun tap(onSingleTap: (tapQuantity: Int) -> Unit, onDoubleTap: (tapQuantity: Int) -> Unit) {
    doubleTapView.setOnTouchListener(object : View.OnTouchListener {
      val gestureDetector =
        GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
          override fun onDoubleTap(e: MotionEvent): Boolean {
            tappedQuantity++
            timeoutWork.cancelTimer()
            effect.fadeIn(100)
            timeoutWork.createTask {
              effect.fadeOut(100)
              tappedQuantity = 0
            }
            onDoubleTap(tappedQuantity)
            return super.onDoubleTap(e)
          }

          override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
            if (tappedQuantity > 0) {
              tappedQuantity++
            }
            timeoutWork.cancelTimer()
            if (effect.visibility == PlayerView.VISIBLE) {
              timeoutWork.createTask {
                tappedQuantity = 0
                effect.fadeOut(100)
              }
            }
            onSingleTap(tappedQuantity)
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
