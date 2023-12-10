//
//  CustomNativeControllers.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 08/12/23.
//

import Foundation
import AVKit

class PlayPause {
  private weak var _player: AVPlayer?
  private weak var _view: UIView!
  private var _shapeLayer = CustomCAShapeLayers()
  private var _layer = CAShapeLayer()
  
  init(video: AVPlayer!, view: UIView!, initialShapeLayer: CAShapeLayer!) {
    _player = video
    _view = view
    _layer = initialShapeLayer
  }
  

  
  
  public func button() {
    let svgPauseLayer = _shapeLayer.createPauseShapeLayer()
    let halfSize = svgPauseLayer.bounds.height / 2
    
    svgPauseLayer.frame.origin = CGPoint(x: _view.bounds.midX, y: _view.bounds.midY - halfSize)
    
    let svgPlayLayer = _shapeLayer.createPlayShapeLayer()
    svgPlayLayer.frame.origin = CGPoint(x: _view.bounds.midX - halfSize / 2, y: _view.bounds.midY - halfSize)
    
    if _player?.rate == 0 {
      _player?.play()
      _layer = svgPauseLayer
    } else {
      _player?.pause()
      _layer = svgPlayLayer
    }
    
    let transition = CATransition()
    transition.type = .reveal
    transition.duration = 1.0
    
    
    _view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    _view.layer.sublayers?.forEach { $0.add(transition, forKey: nil)}
    _view.layer.addSublayer(_layer)
  }
}
