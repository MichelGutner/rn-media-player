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
    
    _seekSlider.minimumTrackTintColor = hexStringToUIColor(hexColor: minimumTrackColor)
    _seekSlider.maximumTrackTintColor = hexStringToUIColor(hexColor: maximumTrackColor)
    
    circleImage = createCircle(
      size: CGSize(width: thumbSize, height: thumbSize),
      backgroundColor: hexStringToUIColor(hexColor: thumbColor)
    )
    _seekSlider.setThumbImage(circleImage, for: .normal)
    _seekSlider.setThumbImage(circleImage, for: .highlighted)
  }
}
