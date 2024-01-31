//
//  SpeedRateLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 20/01/24.
//

import Foundation

@available(iOS 13.0, *)
class PlayBackSpeedLayoutManager {
  private var _button = UIButton()
  private var _view = UIStackView()
  
  init(_ view: UIStackView) {
    self._view = view
  }
  
  public func createAndAdjustLayout() {
    _button.setBackgroundImage(UIImage(systemName: "timer"), for: .normal)
    _button.tintColor = .white
    _button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _button.widthAnchor.constraint(equalToConstant: size20v02),
      _button.heightAnchor.constraint(equalToConstant: size20v02)
      
    ])
  }
  
  public func button() -> UIButton {
    return _button
  }
}
