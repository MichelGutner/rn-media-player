//
//  titleLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 10/01/24.
//

import Foundation

@available(iOS 13.0, *)
class GoBackLayoutManager {
  private var _view = UIView()
  private var _button = UIButton()
  
  init(_ view: UIView) {
    self._view = view
  }
  
  public func createAndAdjustLayout(config: NSDictionary?) {
    let size = calculateFrameSize(size22, variantPercent10)
    let color = config?["color"] as? String
    let isHidden = config?["hidden"] as? Bool
    
    _button.tintColor = transformStringIntoUIColor(color: color)
    _button.setBackgroundImage(UIImage(systemName: "arrow.left"), for: .normal)
    _button.isHidden = isHidden ?? false
    _view.addSubview(_button)
    _button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _button.leadingAnchor.constraint(equalTo: _view.layoutMarginsGuide.leadingAnchor, constant: margin8),
      _button.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _view.layoutMarginsGuide.topAnchor, constant: margin8),
      _button.widthAnchor.constraint(equalToConstant: size),
      _button.heightAnchor.constraint(equalToConstant: size)
    ])
  }
  
  public func button() -> UIButton {
    return _button
  }
}
