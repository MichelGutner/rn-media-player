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
import com.rnvideoplayer.helpers.TimeoutWork
import com.rnvideoplayer.utils.fadeIn
import com.rnvideoplayer.utils.fadeOut
import com.rnvideoplayer.utils.scaleView

@SuppressLint("SetTextI18n")
class CustomDoubleTapSeek(
  val context: ThemedReactContext,
  view: View,
  doubleTapViewId: Int,
  doubleTapEffectId: Int,
  doubleTapTextId: Int,
  isForward: Boolean
) {
  private var doubleTapView: LinearLayout = view.findViewById(doubleTapViewId)
  var effect: RelativeLayout = view.findViewById(doubleTapEffectId)
  var doubleTapText: TextView = view.findViewById(doubleTapTextId)
  var tappedQuantity: Int = 0
  val timeoutWork = TimeoutWork()

  init {
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
            tappedQuantity++
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
