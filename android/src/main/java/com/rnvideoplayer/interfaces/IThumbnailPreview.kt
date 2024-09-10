package com.rnvideoplayer.interfaces

interface IThumbnailPreview {
  fun setCurrentImageBitmapByIndex(index: Int)
  fun show()
  fun hide()
  fun generatingThumbnailFrames(url: String)
}
