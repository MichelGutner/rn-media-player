package com.rnvideoplayer.interfaces

interface ICustomThumbnailPreview {
  fun setCurrentImageBitmapByIndex(index: Int)
  fun show()
  fun hide()
  fun generatingThumbnailFrames(url: String)
}
