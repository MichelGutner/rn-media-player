package com.rnvideoplayer.interfaces

interface IThumbnailPreview {
  fun setCurrentThumbnailImage(index: Int)
  fun show()
  fun hide()
  fun downloadFrames(url: String)
}
