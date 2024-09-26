package com.rnvideoplayer.components

import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.view.View
import android.view.ViewTreeObserver
import android.widget.ImageView
import android.widget.TextView
import androidx.core.graphics.drawable.RoundedBitmapDrawableFactory
import com.rnvideoplayer.R
import com.rnvideoplayer.fadeIn
import com.rnvideoplayer.interfaces.IThumbnailPreview
import kotlin.concurrent.thread

class ThumbnailPreview(view: View) : IThumbnailPreview {
  private var timestamp = 0L
  val interval = 5000L
  val bitmaps = ArrayList<Bitmap>()
  val imageView = view.findViewById<ImageView>(R.id.preview_image_view)
  private val timeCodesPreview = view.findViewById<TextView>(R.id.time_codes_preview)
  var translateXTimesCodePreview: Int = 0

  var translationX = 0f
  var width = 0; private set

  init {
    translateXTimesCodePreview = 850 / 2 - timeCodesPreview.width / 2
    imageView.visibility = View.INVISIBLE
    timeCodesPreview.visibility = View.INVISIBLE
  }

  override fun setCurrentImageBitmapByIndex(index: Int) {
    val bitmap = bitmaps[index]
    val roundedDrawable = RoundedBitmapDrawableFactory.create(imageView.context.resources, bitmap)
    roundedDrawable.cornerRadius = imageView.context.resources.getDimension(R.dimen.corner_radius)
    roundedDrawable.isFilterBitmap = true
    imageView.setImageDrawable(roundedDrawable)

    translateXTimesCodePreview = ((translationX + 850 / 2 - timeCodesPreview.width / 2).toInt())
    imageView.translationX = translationX
    timeCodesPreview.translationX = translateXTimesCodePreview.toFloat()
  }

  override fun show() {
    if (bitmaps.size > 1) {

      // Defina a largura e altura final desejada
      val targetWidth = 850
      val targetHeight = 500

      // Definir a largura inicial do ImageView se necessário
      imageView.layoutParams = imageView.layoutParams.apply {
        width = 0
        height = 0
      }

      imageView.viewTreeObserver.addOnGlobalLayoutListener(object :
        ViewTreeObserver.OnGlobalLayoutListener {
        override fun onGlobalLayout() {
          imageView.viewTreeObserver.removeOnGlobalLayoutListener(this)

          val widthAnimator = ValueAnimator.ofInt(imageView.width, targetWidth)
          widthAnimator.addUpdateListener { animator ->
            val animatedValue = animator.animatedValue as Int
            val layoutParams = imageView.layoutParams
            layoutParams.width = animatedValue
            imageView.layoutParams = layoutParams
          }

          val heightAnimator = ValueAnimator.ofInt(imageView.height, targetHeight)
          heightAnimator.addUpdateListener { animator ->
            val animatedValue = animator.animatedValue as Int
            val layoutParams = imageView.layoutParams
            layoutParams.height = animatedValue
            imageView.layoutParams = layoutParams
          }

          // Combinar as animações e definir a duração
          AnimatorSet().apply {
            playTogether(widthAnimator, heightAnimator)
            duration = 500
            start()
          }
        }
      })
      imageView.fadeIn()
      timeCodesPreview.fadeIn()
    }
  }


  override fun hide() {
    imageView.visibility = View.INVISIBLE
    timeCodesPreview.visibility = View.INVISIBLE
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
