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
class PlayPause {
  private var _button = UIButton()
  private weak var _player: AVPlayer!
  private var _view: UIView!
  
  init(_ player: AVPlayer!, _ view: UIView!) {
    self._player = player
    self._view = view
  }
  
  public func crateAndAdjustLayout() {
    _button.tintColor = .white
    _button.backgroundColor = UIColor(white: 0, alpha: 0.4)
    _button.layer.cornerRadius = 30 / 2.0
    _view.addSubview(_button)
    _button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      _button.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
      _button.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
      _button.widthAnchor.constraint(equalToConstant: 50),
      _button.heightAnchor.constraint(equalToConstant: 50)
    ])
    if _button.imageView?.layer.sublayers == nil && _player.status == .readyToPlay {
      _button.setImage(UIImage(systemName: _player.rate == 0 ? "play.fill" : "pause"), for: .normal)
    }
    
  }

  public func button() -> UIButton {
    return _button
  }
}
