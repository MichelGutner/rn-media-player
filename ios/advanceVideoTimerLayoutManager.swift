//
//  forward.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 07/01/24.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
class AdvanceVideoTimerComponent {
  let defaultVideo = Default()
  private var _button = UIButton()
  private var uiView: UIView!
  
  init(_ view: UIView) {
    self.uiView = view
  }
  
  
  public func createAndAdjustLayout(isForward: Bool) {
    let layoutPosition = isForward ? uiView.bounds.width * 0.2 : -uiView.bounds.width * 0.2
    let image = isForward ? "goforward.10" : "gobackward.10"
    
    _button.setBackgroundImage(UIImage(systemName: image), for: .normal)
    uiView.addSubview(_button)
    _button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _button.centerXAnchor.constraint(equalTo: uiView.layoutMarginsGuide.centerXAnchor, constant: layoutPosition),
      _button.centerYAnchor.constraint(equalTo: uiView.centerYAnchor),
      _button.widthAnchor.constraint(equalToConstant: defaultVideo.controlSize()),
      _button.heightAnchor.constraint(equalToConstant: defaultVideo.controlSize())
    ])
  }
  
  public func button() -> UIButton {
    return _button
  }
}
