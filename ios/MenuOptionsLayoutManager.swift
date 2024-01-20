//
//  moreOptionsLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 10/01/24.
//

import Foundation

@available(iOS 13.0, *)
class MenuOptionsLayoutManager {
  private var _button = UIButton()
  private var _view: UIView
  
  init(_ view: UIView) {
    self._view = view
  }
  
  public func createAndAdjustLayout(config: NSDictionary?) {
    let size = calculateFrameSize(18, 0.2)
    let trailingAnchor = calculateFrameSize(60, 0.2)
    
    let color = config?["color"] as? String
    let isHidden = config?["color"] as? Bool
    
    
    _button.setBackgroundImage(UIImage(systemName: "gear"), for: .normal)
    _button.tintColor = hexStringToUIColor(hexColor: color)
    _button.isHidden = isHidden ?? false
    _view.addSubview(_button)
    _button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _button.trailingAnchor.constraint(equalTo: _view.layoutMarginsGuide.trailingAnchor, constant: -trailingAnchor),
      _button.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _view.layoutMarginsGuide.topAnchor, constant: 8),
      _button.widthAnchor.constraint(equalToConstant: size),
      _button.heightAnchor.constraint(equalToConstant: size)
    ])
  }
  
  public func button() -> UIButton{
    return _button
  }
}
