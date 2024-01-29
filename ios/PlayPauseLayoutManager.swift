//
//  playPause.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 01/01/24.
//

import Foundation
import AVKit
import UIKit

@available(iOS 13.0, *)
class PlayPauseLayoutManager {
  private var _button = UIButton()
  private weak var _player: AVPlayer!
  private var _view: UIView!
  
  init(_ player: AVPlayer!, _ view: UIView!) {
    self._player = player
    self._view = view
  }
  
  public func crateAndAdjustLayout(config: NSDictionary?) {
    let tintColor = config?["color"] as? String
    let isHidden = config?["hidden"] as? Bool
    
    let size = (calculateFrameSize(size30, variantPercent02) + size20)
    
    _button.tintColor = transformStringIntoUIColor(color: tintColor)
    _button.isHidden = isHidden ?? false
    _button.backgroundColor = UIColor(white: 0, alpha: 0.4)
    _button.layer.cornerRadius = size16
    _view.addSubview(_button)
    _button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _button.centerXAnchor.constraint(equalTo: _view.layoutMarginsGuide.centerXAnchor),
      _button.safeAreaLayoutGuide.centerYAnchor.constraint(equalTo: _view.layoutMarginsGuide.centerYAnchor),
      _button.widthAnchor.constraint(equalToConstant: size),
      _button.heightAnchor.constraint(equalToConstant:  size),
    ])
    if _button.imageView?.layer.sublayers == nil {
      _button.setImage(UIImage(systemName: _player.rate == 0 ? "play.fill" : "pause"), for: .normal)
    }
  }

  public func button() -> UIButton {
    return _button
  }
}
