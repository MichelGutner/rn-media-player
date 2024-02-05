//
//  forward.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 07/01/24.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
class ForwardLayoutManager {
  private var _button = UIButton()
  private var uiView: UIView!
  
  init(_ view: UIView) {
    self.uiView = view
  }
  
  
  public func createAndAdjustLayout(config: NSDictionary?) {
    let size = calculateFrameSize(size30, variantPercent10)
    
    let layoutPosition = uiView.bounds.width * variantPercent20
    configureLayoutForward(config)
    uiView.addSubview(_button)
    
    _button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _button.centerXAnchor.constraint(equalTo: uiView.layoutMarginsGuide.centerXAnchor, constant: layoutPosition),
      _button.safeAreaLayoutGuide.centerYAnchor.constraint(equalTo: uiView.layoutMarginsGuide.centerYAnchor),
      _button.widthAnchor.constraint(equalToConstant: size),
      _button.heightAnchor.constraint(equalToConstant: size)
    ])
  }
  
  public func button() -> UIButton {
    return _button
  }
}

@available(iOS 13.0, *)
extension ForwardLayoutManager {
  private func configureLayoutForward(_ config: NSDictionary?) {
    let color = config?["color"] as? String
    let hidden = config?["hidden"] as? Bool
    let image = config?["image"] as? String
    let imageType = EImageForward(rawValue: image ?? "")
    
    _button.tintColor = transformStringIntoUIColor(color: color)
    _button.isHidden = hidden ?? false
    _button.setBackgroundImage(UIImage(systemName: generateImageByType(imageType ?? .forwardDefault)), for: .normal)
  }
  
  private func generateImageByType(_ image: EImageForward) -> String {
    switch(image) {
    case .forwardEmpty:
      return "goforward"
    case .forward15:
      return "goforward.15"
    case .forward30:
      return "goforward.30"
    case .forward45:
      return "goforward.45"
    case .forward60:
      return "goforward.60"
    case .forward75:
      return "goforward.75"
    case .forward90:
      return "goforward.90"
    case .forwardDefault:
      return "goforward.10"
    }
  }
}

enum EImageForward: String {
  case forwardEmpty
  case forward15
  case forward30
  case forward45
  case forward60
  case forward75
  case forward90
  case forwardDefault
}
