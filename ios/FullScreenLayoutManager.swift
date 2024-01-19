//
//  fullScreenButton.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 08/12/23.
//

import Foundation


class FullScreenLayoutManager {
  private var _button = UIButton()
  private var _view = UIView()
  
  init(_ view: UIView) {
    _view = view
  }
  
  public func createAndAdjustLayout(config: NSDictionary?) {
    let size = calculateSizeByWidth(18, 0.2)
    let fullScreenProps = config
    let color = fullScreenProps?["color"] as? String
    
    _button.tintColor = hexStringToUIColor(hexColor: color)
    _view.addSubview(_button)
    _button.translatesAutoresizingMaskIntoConstraints = false
    _button.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 0.5)
    
    NSLayoutConstraint.activate([
      _button.trailingAnchor.constraint(equalTo: _view.layoutMarginsGuide.trailingAnchor, constant: -20),
      _button.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _view.layoutMarginsGuide.topAnchor, constant: 8),
      _button.widthAnchor.constraint(equalToConstant: size),
      _button.heightAnchor.constraint(equalToConstant: size)
    ])
  }
  
  public func button() -> UIButton {
    return _button
  }
}
