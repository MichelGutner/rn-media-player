//
//  SeekSliderLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 10/01/24.
//

import Foundation

class SeekSliderLayoutManager {
  private var _view: UIView
  private var _seekSlider = UISlider(frame:CGRect(x: 0, y:UIScreen.main.bounds.height - 60, width:UIScreen.main.bounds.width, height:10))
  private var circleImage: UIImage!
  
  init(_ view: UIView) {
    self._view = view
  }
  
  public func createAndAdjustLayout(config: NSDictionary?) {
    configureThumb(config)
    _view.addSubview(_seekSlider)
    _seekSlider.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _seekSlider.leadingAnchor.constraint(
        equalTo: _view.layoutMarginsGuide.leadingAnchor, constant: 60
      ),
      _seekSlider.trailingAnchor.constraint(
        equalTo: _view.layoutMarginsGuide.trailingAnchor, constant: -60
      ),
      _seekSlider.safeAreaLayoutGuide.bottomAnchor.constraint(
        equalTo: _view.layoutMarginsGuide.bottomAnchor
      ),
    ])
  }
  
  public func seekSlider() -> UISlider {
    return _seekSlider
  }
}

extension SeekSliderLayoutManager {
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
