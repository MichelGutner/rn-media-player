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
import com.rnvideoplayer.utils.fadeIn
import com.rnvideoplayer.utils.fadeOut
import com.rnvideoplayer.utils.scaleView
import java.util.Timer
import java.util.TimerTask

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
  private var timer = Timer()
  private var resetTimerTask: TimerTask? = null


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
            resetTimerTask?.cancel()
            effect.fadeIn(100)
            onTimerTask() {
              effect.fadeOut(100)
            }
            onDoubleTap()
            return super.onDoubleTap(e)
          }

          override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
            resetTimerTask?.cancel()
            if (effect.visibility == PlayerView.VISIBLE) {
              onTimerTask() {
                effect.fadeOut(100)
              }
            }
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

  fun onTimerTask(resetDuration: Long = 1000, callback: () -> Unit) {
    resetTimerTask = object : TimerTask() {
      override fun run() {
        callback()
      }
    }
    timer.schedule(resetTimerTask, resetDuration)
  }

}
