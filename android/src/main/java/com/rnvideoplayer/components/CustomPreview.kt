package com.rnvideoplayer.components

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.view.View
import android.widget.ImageView
import com.facebook.react.uimanager.ThemedReactContext
import com.rnvideoplayer.R
import com.rnvideoplayer.interfaces.ICustomThumbnailPreview
import kotlin.concurrent.thread

class CustomThumbnailPreview(context: ThemedReactContext, view: View) : ICustomThumbnailPreview {
  private var timestamp = 0L
  val interval = 5000L
  val bitmaps = ArrayList<Bitmap>()
  private val thumbnail = view.findViewById<ImageView>(R.id.preview_image_view)
  var translationX = 0f;
  var width = 0; private set

  init {
    thumbnail.viewTreeObserver.addOnGlobalLayoutListener {
      width = thumbnail.width
    }
    thumbnail.visibility = View.GONE
  }

  override fun setCurrentImageBitmapByIndex(index: Int) {
    thumbnail.translationX = translationX
    thumbnail.setImageBitmap(bitmaps[index])
  }

  override fun show() {
    thumbnail.visibility = View.VISIBLE
  }

  override fun hide() {
    thumbnail.visibility = View.GONE
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
}
