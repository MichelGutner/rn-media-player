//
//  QualityLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 26/01/24.
//

import Foundation

@available(iOS 13.0, *)
class QualityLayoutManager {
  private var _button = UIButton()
  private var _view = UIView()

  init(_ view: UIView) {
    self._view = view
  }

  public func createAndAdjustLayout() {
    let size = calculateFrameSize(size24, variantPercent30)
    let trailingAnchor = calculateFrameSize(90, 0.2)

    _button.setBackgroundImage(UIImage(systemName: "chart.bar.fill"), for: .normal)
    _view.addSubview(_button)
    _button.tintColor = .white
    _button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _button.trailingAnchor.constraint(lessThanOrEqualTo: _view.layoutMarginsGuide.trailingAnchor, constant: -trailingAnchor),
      _button.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _view.layoutMarginsGuide.topAnchor, constant: 8),
      _button.widthAnchor.constraint(equalToConstant: size),
      _button.heightAnchor.constraint(equalToConstant: size)

    ])
  }

  public func button() -> UIButton {
    return _button
  }

}
