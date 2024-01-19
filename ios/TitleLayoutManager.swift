//
//  titleLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 10/01/24.
//

import Foundation

@available(iOS 13.0, *)
class TitleLayoutManager {
  private var _title = UILabel()
  private var _view = UIView()
  
  init(_ view: UIView) {
    self._view = view
  }
  
  public func createAndAdjustLayout() {
    let size = calculateSizeByWidth(18, 0.1)
    _title.textColor = .white
    _title.font = UIFont.systemFont(ofSize: size)
    _view.addSubview(_title)
    _title.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _title.leadingAnchor.constraint(equalTo: _view.layoutMarginsGuide.leadingAnchor, constant: 0),
      _title.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _view.layoutMarginsGuide.topAnchor, constant: 4)
    ])
  }
  
  public func title() -> UILabel {
    return _title
  }
}
