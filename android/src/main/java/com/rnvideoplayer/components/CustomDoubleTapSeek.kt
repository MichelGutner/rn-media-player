package com.rnvideoplayer.components

import android.annotation.SuppressLint
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.RelativeLayout
import android.widget.TextView
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.utils.fadeIn
import com.rnvideoplayer.utils.scaleView

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
  private var doubleTapText: TextView = view.findViewById(doubleTapTextId)


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
  fun tap(onSingleTap: () -> Unit, onDoubleTap: () -> Unit) {
    doubleTapView.setOnTouchListener(object : View.OnTouchListener {
      val gestureDetector =
        GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
          override fun onDoubleTap(e: MotionEvent): Boolean {
            effect.fadeIn(100)
            onDoubleTap()
            return super.onDoubleTap(e)
          }

          override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
            onSingleTap()
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
