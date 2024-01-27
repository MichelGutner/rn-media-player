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
    let trailingAnchor = calculateFrameSize(size20, variantPercent02)
    let fullScreenProps = config
    let color = fullScreenProps?["color"] as? String
    let isHidden = fullScreenProps?["hidden"] as? Bool
    
    _button.isHidden = isHidden ?? false
    _button.tintColor = transformStringIntoUIColor(color: color)
    _view.addSubview(_button)
    _button.translatesAutoresizingMaskIntoConstraints = false
    _button.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 0.5)
    
    NSLayoutConstraint.activate([
      _button.trailingAnchor.constraint(equalTo: _view.layoutMarginsGuide.trailingAnchor, constant: -trailingAnchor),
      _button.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: _view.layoutMarginsGuide.bottomAnchor),
      _button.widthAnchor.constraint(equalToConstant: size20v02),
      _button.heightAnchor.constraint(equalToConstant: size20v02)
    ])
  }
  
  public func button() -> UIButton {
    return _button
  }
}
