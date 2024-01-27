//
//  SeekSliderLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 10/01/24.
//

import Foundation

class SeekSliderLayoutManager {
  private var _view: UIView
  private var _seekSlider = UISlider(frame: .zero)
  private var circleImage: UIImage!
  
  init(_ view: UIView) {
    self._view = view
  }
  
  public func seekSlider() -> UISlider {
    return _seekSlider
  }
  private func configureThumb(_ config: NSDictionary?) {
    guard let sliderProps = config,
          let minimumTrackColor = sliderProps["minimumTrackColor"] as? String,
          let maximumTrackColor = sliderProps["maximumTrackColor"] as? String,
          let thumbSize = sliderProps["thumbSize"] as? CGFloat,
          let thumbColor = sliderProps["thumbColor"] as? String else {
      return
    }
    
    _seekSlider.minimumTrackTintColor = transformStringIntoUIColor(color: minimumTrackColor)
    _seekSlider.maximumTrackTintColor = transformStringIntoUIColor(color: maximumTrackColor)
    
    circleImage = createCircleImage(
      size: CGSize(width: thumbSize, height: thumbSize),
      backgroundColor: transformStringIntoUIColor(color: thumbColor)
    )
    _seekSlider.setThumbImage(circleImage, for: .normal)
    _seekSlider.setThumbImage(circleImage, for: .highlighted)
  }
}
