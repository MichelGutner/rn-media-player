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
  
  public func createAndAdjustLayout() {
    _button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
    _button.tintColor = .white
    _button.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 0.5)
    _view.addSubview(_button)
    _button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _button.trailingAnchor.constraint(equalTo: _view.layoutMarginsGuide.trailingAnchor, constant: -60),
      _button.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _view.layoutMarginsGuide.topAnchor, constant: 4),
      _button.widthAnchor.constraint(equalToConstant: controlDefaultSize),
      _button.heightAnchor.constraint(equalToConstant: controlDefaultSize)
    ])
  }
  
  public func button() -> UIButton{
    return _button
  }
}
