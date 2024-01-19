//
//  forward.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 07/01/24.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
class BackwardLayoutManager {
  private var _button = UIButton()
  private var uiView: UIView!
  
  init(_ view: UIView) {
    self.uiView = view
  }
  
  
  public func createAndAdjustLayout(config: NSDictionary?) {
    let size = calculateSizeByWidth(controlDefaultSize, 0.1)
    
    let layoutPosition = -uiView.bounds.width * 0.2
    configureLayoutBackward(config)
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
extension BackwardLayoutManager {
  private func configureLayoutBackward(_ config: NSDictionary?) {
    let advanceLayoutProps = config
    let color = advanceLayoutProps?["color"] as? String
    let hidden = advanceLayoutProps?["hidden"] as? Bool
    let image = advanceLayoutProps?["image"] as? String
    
    let imageType = EImageBackward(rawValue: image ?? "")
    
    _button.tintColor = hexStringToUIColor(hexColor: color)
    _button.isHidden = hidden ?? false
    _button.setBackgroundImage(UIImage(systemName: generateImageByType(imageType ?? .backwardDefault)), for: .normal)
  }
  
  private func generateImageByType(_ image: EImageBackward) -> String {
    switch(image) {
    case .backwardEmpty:
      return "gobackward"
    case .backward15:
      return "gobackward.15"
    case .backward30:
      return "gobackward.30"
    case .backward45:
      return "gobackward.45"
    case .backward60:
      return "gobackward.60"
    case .backward75:
      return "gobackward.75"
    case .backward90:
      return "gobackward.90"
    case .backwardDefault:
      return "gobackward.10"
    }
  }
}


enum EImageBackward: String {
  case backwardEmpty
  case backward15
  case backward30
  case backward45
  case backward60
  case backward75
  case backward90
  case backwardDefault
}
