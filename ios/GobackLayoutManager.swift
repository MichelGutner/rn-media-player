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
  
  public func createAndAdjustLayout() {
    _button.tintColor = .white
    _button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
    _view.addSubview(_button)
    _button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _button.leadingAnchor.constraint(equalTo: _view.layoutMarginsGuide.leadingAnchor, constant: 8),
      _button.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _view.layoutMarginsGuide.topAnchor, constant: 4)
    ])
  }
  
  public func button() -> UIButton {
    return _button
  }
}
