package com.rnvideoplayer.ui.components

import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.graphics.drawable.RoundedBitmapDrawableFactory
import com.rnvideoplayer.R
import com.rnvideoplayer.fadeIn
import com.rnvideoplayer.fadeOut
import com.rnvideoplayer.helpers.RNVideoHelpers
import com.rnvideoplayer.interfaces.IThumbnailPreview
import com.rnvideoplayer.utilities.ColorUtils
import kotlin.concurrent.thread

class Thumbnails(context: Context) : FrameLayout(context), IThumbnailPreview {
  private val helper = RNVideoHelpers()
  private var timestamp = 0L
  private val thumbWidth = 850
  private val thumbHeight = 500

  val interval = 5000L
  val bitmaps = ArrayList<Bitmap>()
  private val imageView = LinearLayout(context).apply {
    layoutParams = ViewGroup.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
      orientation = LinearLayout.VERTICAL
    }
  }
  val thumbnailView = createThumbnailView(context)
  private val thumbnailTimeCodes = createThumbnailTimeCodes(context)
  var translateXTimesCodePreview: Int = 0

  var translationXThumbnailView = 0f

  init {
    imageView.addView(thumbnailView)
    imageView.addView(thumbnailTimeCodes)
    addView(imageView)
    translateXTimesCodePreview = thumbWidth / 2 - thumbnailTimeCodes.width / 2
  }

  override fun setCurrentImageBitmapByIndex(index: Int) {
    val bitmap = bitmaps[index]
    val roundedDrawable = RoundedBitmapDrawableFactory.create(thumbnailView.context.resources, bitmap)
    roundedDrawable.cornerRadius = thumbnailView.context.resources.getDimension(R.dimen.corner_radius)
    roundedDrawable.isFilterBitmap = true
    thumbnailView.setImageDrawable(roundedDrawable)

    translateXTimesCodePreview = ((translationXThumbnailView + 850 / 2 - thumbnailTimeCodes.width / 2).toInt())
    thumbnailView.translationX = translationXThumbnailView
    thumbnailTimeCodes.translationX = translateXTimesCodePreview.toFloat()
  }

  override fun show() {
    if (bitmaps.size > 1) {
      thumbnailView.fadeIn()
      thumbnailTimeCodes.fadeIn()
      //@@TODO: need fix into appear animation
//      thumbnailView.layoutParams = thumbnailView.layoutParams.apply {
//        width = 400
//        height = 0
//      }
//      viewTreeObserver.addOnGlobalLayoutListener(object :
//        ViewTreeObserver.OnGlobalLayoutListener {
//        override fun onGlobalLayout() {
//          viewTreeObserver.removeOnGlobalLayoutListener(this)
//
//          val widthAnimator = ValueAnimator.ofInt(thumbnailView.width, thumbWidth)
//          widthAnimator.addUpdateListener { animator ->
//            val animatedValue = animator.animatedValue as Int
//            val layoutParams = thumbnailView.layoutParams
//            layoutParams.width = animatedValue
//            thumbnailView.layoutParams = layoutParams
//          }
//
//          val heightAnimator = ValueAnimator.ofInt(thumbnailView.height, thumbHeight)
//          heightAnimator.addUpdateListener { animator ->
//            val animatedValue = animator.animatedValue as Int
//            val layoutParams = thumbnailView.layoutParams
//            layoutParams.height = animatedValue
//            thumbnailView.layoutParams = layoutParams
//          }
//
//          AnimatorSet().apply {
//            playTogether(widthAnimator, heightAnimator)
//            duration = 500
//            start()
//          }
//        }
//      })
    }
  }


  override fun hide() {
    thumbnailView.fadeOut()
    thumbnailTimeCodes.fadeOut()
  }


  override fun generatingThumbnailFrames(url: String) {
    thread {
      val retriever = MediaMetadataRetriever()
      retriever.setDataSource(url)

      val durationString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
      val duration = durationString?.toLong() ?: 0

      while (timestamp < duration) {
        val bitmap =
          retriever.getFrameAtTime(timestamp * 1000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
        if (bitmap != null) {
          bitmaps.add(bitmap)
          timestamp += interval
        }
      }
      retriever.release()
    }
  }

  fun getCurrentPlayerPosition(position: Long) {
    thumbnailTimeCodes.text = helper.createTimeCodesFormatted(position)
  }

  private fun createThumbnailView(context: Context): ImageView {
    val imageView = ImageView(context).apply {
      layoutParams = ViewGroup.LayoutParams(thumbWidth, thumbHeight).apply {
        setBackgroundResource(R.drawable.rounded_corner_background)
        isClickable = false
        isFocusable = false
        visibility = INVISIBLE
        scaleType = ImageView.ScaleType.FIT_XY
      }
    }
    return imageView
  }

  private fun createThumbnailTimeCodes(context: Context): TextView {
    val timeCodes = TextView(context).apply {
      layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
        text = context.getString(R.string.time_codes_start_value)
        textSize = 12f
        setTextColor(ColorUtils.white)
        visibility = INVISIBLE
      }
    }
    return timeCodes
  }
}
