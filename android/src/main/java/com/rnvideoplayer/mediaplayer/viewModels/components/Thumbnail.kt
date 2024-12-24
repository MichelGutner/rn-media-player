package com.rnvideoplayer.mediaplayer.viewModels.components

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.graphics.drawable.RoundedBitmapDrawableFactory
import com.rnvideoplayer.R
import com.rnvideoplayer.extensions.fadeIn
import com.rnvideoplayer.extensions.fadeOut
import com.rnvideoplayer.interfaces.IThumbnailPreview
import com.rnvideoplayer.utilities.ColorUtils
import com.rnvideoplayer.utils.TimeCodesFormat
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

class Thumbnail(context: Context) : LinearLayout(context), IThumbnailPreview {
  private val helper = TimeCodesFormat()
  private var timestamp = 0L
  private val thumbWidth = dpToPx(240)
  private val thumbHeight = dpToPx(140)
  private val interval = TimeUnit.MILLISECONDS.toSeconds(5000L)
  private val bitmaps = ArrayList<Bitmap>()

  private val thumbnailView = thumbnailImage(context)
  private val thumbnailTimeCodes = createThumbnailTimeCodes(context)
  private var translateXTimeCodes: Int = 0

  var translationXThumbnailView = 0f

  init {
    layoutParams = LayoutParams(
      0,
      LayoutParams.WRAP_CONTENT
    ).apply {
      weight = 1f
      orientation = VERTICAL
      gravity = Gravity.BOTTOM
    }
    visibility = INVISIBLE
    addView(thumbnailView)
    addView(thumbnailTimeCodes)
  }

  override fun setCurrentThumbnailImage(index: Int) {
    val bitmap = bitmaps[index]
    val roundedDrawable =
      RoundedBitmapDrawableFactory.create(thumbnailView.context.resources, bitmap)

    roundedDrawable.cornerRadius =
      thumbnailView.context.resources.getDimension(R.dimen.corner_radius)
    roundedDrawable.isFilterBitmap = true
    thumbnailView.setImageDrawable(roundedDrawable)
  }

  fun onTranslate(seconds: Double, duration: Double, customWidth: Int? = null) {
    val parent = (this.parent as ViewGroup)
    val widthTarget = (customWidth ?: parent.width)
    val currentIndex = (seconds / interval).toInt()
    val currentSeekPoint =
      ((((seconds * 100) / duration) * widthTarget) / 100)

    var translateX = 16.0F
    if ((currentSeekPoint.toFloat() + thumbWidth / 2) + parent.width * 0.01F >= widthTarget) {
      translateX = (widthTarget - thumbWidth) - parent.width * 0.01F
    } else if (currentSeekPoint.toFloat() >= thumbWidth / 2 && currentSeekPoint.toFloat() + thumbWidth / 2 < widthTarget) {
      translateX = currentSeekPoint.toFloat() - thumbWidth / 2
    }

    if (currentIndex < bitmaps.size) {
      this.setCurrentThumbnailImage(currentIndex)
      translateXTimeCodes = ((translateX + thumbWidth / 2 - thumbnailTimeCodes.width / 2).toInt())
      thumbnailView.translationX = translateX
      thumbnailTimeCodes.translationX = translateXTimeCodes.toFloat()
    }
  }

  override fun show() {
    if (bitmaps.size > 1) {
      fadeIn()
    }
  }

  override fun hide() {
    fadeOut()
  }

  override fun downloadFrames(url: String) {
    bitmaps.clear()
    timestamp = 0

    val handler = Handler(Looper.getMainLooper())
    thread {
      val retriever = MediaMetadataRetriever()
      try {
        retriever.setDataSource(url)
      } catch (e: IllegalArgumentException) {
        e.printStackTrace()
        return@thread
      }

      val durationString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
      val duration = durationString?.toLong() ?: 0

      while (timestamp < duration) {
        val bitmap =
          retriever.getFrameAtTime(timestamp * 1000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)

        if (bitmap != null) {
          bitmaps.add(bitmap)
          timestamp += 5000L
        }
      }
      retriever.release()
      handler.post {}
    }
  }

  fun updatePosition(position: Long) {
    thumbnailTimeCodes.text = helper.format(position)
  }

  private fun thumbnailImage(context: Context): ImageView {
    val imageView = ImageView(context).apply {
      layoutParams = ViewGroup.LayoutParams(thumbWidth, thumbHeight).apply {
        setBackgroundResource(R.drawable.rounded_corner_background)
        isClickable = false
        isFocusable = false
        scaleType = ImageView.ScaleType.FIT_XY
      }
    }
    return imageView
  }

  private fun createThumbnailTimeCodes(context: Context): TextView {
    val timeCodes = TextView(context).apply {
      layoutParams = ViewGroup.LayoutParams(
        ViewGroup.LayoutParams.WRAP_CONTENT,
        ViewGroup.LayoutParams.WRAP_CONTENT
      ).apply {
        text = context.getString(R.string.time_codes_start_value)
        textSize = 12f
        setTextColor(ColorUtils.white)
        translationX = ((thumbWidth / 2) - (ViewGroup.LayoutParams.WRAP_CONTENT / 2)).toFloat()
      }
    }
    return timeCodes
  }

  private fun dpToPx(dp: Int): Int {
    return (dp * context.resources.displayMetrics.density).toInt()
  }
}
