//
//  CustomPlayPause.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 11/03/24.
//

import Foundation
import UIKit

class PlayPauseButton: UIButton {
  private var action: () -> Void
  private var color: CGColor?
  private var playLeftLayer: CAShapeLayer!
  private var playRightLayer: CAShapeLayer!
  
  private var pauseLeftLayer: CAShapeLayer!
  private var pauseRightLayer: CAShapeLayer!
  
  private var playing: Bool = false
  
  override var isHighlighted: Bool {
    didSet {
      super.isHighlighted = false
    }
  }
  
  init(frame: CGRect, action: @escaping () -> Void, isPlaying: Bool, color: CGColor?) {
    self.action = action
    self.playing = isPlaying
    self.color = color
    
    super.init(frame: frame)
    setupLayers()
    addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    
    NotificationCenter.default.addObserver(forName: .SeekingNotification, object: nil, queue: .main, using: { notification in
      self.isHidden = notification.object as! Bool
    })
    NotificationCenter.default.addObserver(forName: .DoubleTapNotification, object: nil, queue: .main, using: { notification in
      self.isHidden = notification.object as! Bool
    })
    NotificationCenter.default.addObserver(forName: .AVPlayerInitialLoading, object: nil, queue: .main, using: { notification in
      UIView.animate(withDuration: 0.1, animations: {
        self.isHidden = notification.object as! Bool
      })
    })
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  private func setupLayers() {
    self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    self.layer.cornerRadius = self.frame.width
    playLeftLayer = createLayer(path: UIBezierPath.playLeftIcon(bounds: bounds).cgPath)
    playRightLayer = createLayer(path: UIBezierPath.playRightIcon(bounds: bounds).cgPath)
    
    pauseLeftLayer = createLayer(path: UIBezierPath.pauseLeftIcon(bounds: bounds).cgPath)
    pauseRightLayer = createLayer(path: UIBezierPath.pauseRightIcon(bounds: bounds).cgPath)
    
    playLeftLayer.isHidden = playing
    playRightLayer.isHidden = playing
    pauseLeftLayer.isHidden = !playing
    pauseRightLayer.isHidden = !playing
  }
  
  private func createLayer(path: CGPath) -> CAShapeLayer {
    let layer = CAShapeLayer()
    layer.path = path
    layer.fillColor = color ?? CGColor(red: 255, green: 255, blue: 255, alpha: 1)
    layer.strokeColor = color ?? CGColor(red: 255, green: 255, blue: 255, alpha: 1)
    layer.position = .init(x: bounds.midX, y: bounds.midY)
    
    layer.setNeedsDisplay()
    layer.setNeedsLayout()
    layer.layoutIfNeeded()
    
    self.layer.addSublayer(layer)
    
    return layer
  }
  
  @objc private func buttonTapped() {
    playing.toggle()
    self.action()
    animateLayer(playLayer: playLeftLayer, pauseLayer: pauseLeftLayer)
    animateLayer(playLayer: playRightLayer, pauseLayer: pauseRightLayer)
  }
  
  private func animateLayer(playLayer: CAShapeLayer, pauseLayer: CAShapeLayer) {
    let animation = CABasicAnimation(keyPath: "path")
    
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    animation.duration = 0.5
    
    if playing {
      playLayer.isHidden = true
      pauseLayer.isHidden = false
      animation.fromValue = playLayer.path
      animation.toValue = pauseLayer.path
    } else {
      playLayer.isHidden = false
      pauseLayer.isHidden = true
      animation.fromValue = pauseLayer.path
      animation.toValue = playLayer.path
    }
    
    playLayer.add(animation, forKey: "path")
    pauseLayer.add(animation, forKey: "path")
  }
}


