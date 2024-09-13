package com.rnvideoplayer.components

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import androidx.core.view.drawToBitmap
import com.rnvideoplayer.R
import com.rnvideoplayer.interfaces.IThumbnailPreview
import kotlin.concurrent.thread

class ThumbnailPreview(view: View) : IThumbnailPreview {
  private var timestamp = 0L
  val interval = 5000L
  val bitmaps = ArrayList<Bitmap>()
  val view = view.findViewById<ImageView>(R.id.preview_image_view)
  private val timeCodesPreview = view.findViewById<TextView>(R.id.time_codes_preview)
  var translationX = 0f
  var width = 0; private set

  init {
    this.view.viewTreeObserver.addOnGlobalLayoutListener {
      width = this.view.width
    }
  }

  override fun setCurrentImageBitmapByIndex(index: Int) {
    val translateXTimesCodePreview = translationX + view.width / 2 - timeCodesPreview.width / 2

    view.translationX = translationX
    timeCodesPreview.translationX = translateXTimesCodePreview
    view.drawToBitmap(Bitmap.Config.ARGB_8888)
    view.setImageBitmap(bitmaps[index])
  }

  override fun show() {
    if (bitmaps.size <= 5) return
    view.visibility = View.VISIBLE
    timeCodesPreview.visibility = View.VISIBLE
  }

  override fun hide() {
    view.visibility = View.GONE
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
