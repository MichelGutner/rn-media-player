package com.rnvideoplayer.components

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import androidx.core.view.drawToBitmap
import com.rnvideoplayer.R
import com.rnvideoplayer.interfaces.ICustomThumbnailPreview
import kotlin.concurrent.thread

class CustomThumbnailPreview(view: View) : ICustomThumbnailPreview {
  private var timestamp = 0L
  val interval = 5000L
  val bitmaps = ArrayList<Bitmap>()
  private val thumbnail = view.findViewById<ImageView>(R.id.preview_image_view)
  private val timeCodesPreview = view.findViewById<TextView>(R.id.time_codes_preview)
  var translationX = 0f;
  var width = 0; private set

  init {
    thumbnail.viewTreeObserver.addOnGlobalLayoutListener {
      width = thumbnail.width
    }
  }

  override fun setCurrentImageBitmapByIndex(index: Int) {
    val translateXTimesCodePreview = translationX + thumbnail.width / 2 - timeCodesPreview.width / 2

    thumbnail.translationX = translationX
    timeCodesPreview.translationX = translateXTimesCodePreview
    thumbnail.drawToBitmap(Bitmap.Config.ALPHA_8)
    thumbnail.setImageBitmap(bitmaps[index])
  }

  override fun show() {
    if (bitmaps.isEmpty()) return
    thumbnail.visibility = View.VISIBLE
    timeCodesPreview.visibility = View.VISIBLE
  }

  override fun hide() {
    thumbnail.visibility = View.GONE
    timeCodesPreview.visibility = View.GONE
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

  fun getCurrentPlayerPosition(position: String) {
    timeCodesPreview.text = position
  }

}
