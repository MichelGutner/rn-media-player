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
    let layoutPosition = uiView.bounds.width * 0.2
    configureLayoutForward(config)
    uiView.addSubview(_button)
    _button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _button.centerXAnchor.constraint(equalTo: uiView.layoutMarginsGuide.centerXAnchor, constant: layoutPosition),
      _button.safeAreaLayoutGuide.centerYAnchor.constraint(equalTo: uiView.layoutMarginsGuide.centerYAnchor),
      _button.widthAnchor.constraint(equalToConstant: controlDefaultSize),
      _button.heightAnchor.constraint(equalToConstant: controlDefaultSize)
    ])
  }
  
  public func button() -> UIButton {
    return _button
  }
}

@available(iOS 13.0, *)
extension ForwardLayoutManager {
  private func configureLayoutForward(_ config: NSDictionary?) {
    let advanceLayoutProps = config
    let color = advanceLayoutProps?["color"] as? String
    let hidden = advanceLayoutProps?["hidden"] as? Bool
    let image = advanceLayoutProps?["image"] as? String
    let imageType = EImageForward(rawValue: image ?? "")
    
    _button.tintColor = hexStringToUIColor(hexColor: color ?? hexDefaultColor)
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
