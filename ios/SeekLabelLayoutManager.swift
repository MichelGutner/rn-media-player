//
//  SeekLabel.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 07/01/24.
//

import Foundation

class SeekLabelLayoutManager {
  private var _label = UILabel()
  private var uiView: UIView!
  
  init(_ view: UIView) {
    self.uiView = view
  }
  
  
  public func createAndAdjustLayout(isDuration: Bool) {
    _label.textColor = .white
    _label.font = UIFont.systemFont(ofSize: 10)
    let layoutConstraint = isDuration ?
    _label.trailingAnchor.constraint(equalTo: uiView.layoutMarginsGuide.trailingAnchor) :
    _label.leadingAnchor.constraint(equalTo: uiView.layoutMarginsGuide.leadingAnchor)
    if _label.text == nil {
      self._label.text = UtilityStringHandler().stringFromTimeInterval(interval: 0)
    }
    uiView.addSubview(_label)
    _label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      layoutConstraint,
      _label.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: uiView.layoutMarginsGuide.bottomAnchor)
    ])
  }
  
  public func label() -> UILabel {
    return _label
  }
}
