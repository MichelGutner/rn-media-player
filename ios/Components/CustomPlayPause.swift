//
//  CustomPlayPause.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 11/03/24.
//

import Foundation
import UIKit
import SwiftUI

@available(iOS 13.0, *)
struct CustomPlayPauseButton: UIViewRepresentable {
  var action: (Bool) -> Void
  var isPlaying: Bool
  var frame: CGRect
  var color: CGColor?
  
  class Coordinator: NSObject {
    var action: (Bool) -> Void
    var isPlaying: Bool
    var color: CGColor?
    
    init(action: @escaping (Bool) -> Void, _ isPlaying: Bool, _ color: CGColor?) {
      self.action = action
      self.isPlaying = isPlaying
      self.color = color
    }
    
    @objc func buttonTapped() {
      action(isPlaying)
    }
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(action: action, isPlaying, color)
  }
  
  
  func makeUIView(context: Context) -> some UIView {
    let uiView = PlayPauseButton(frame: frame, action: action, isPlaying: isPlaying, color: color)
    uiView.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
    return uiView
  }
  
  func updateUIView(_ uiView: UIViewType, context: Context) {
    //
  }
  
}

@available(iOS 13.0, *)
class PlayPauseButton: UIButton {
  private var action: (Bool) -> Void
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
    
  init(frame: CGRect, action: @escaping (Bool) -> Void, isPlaying: Bool, color: CGColor?) {
    self.action = action
    self.playing = isPlaying
    self.color = color
    
    super.init(frame: frame)
      setupLayers()
      addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

    private func setupLayers() {
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
        self.action(playing)
        animateLayer(playLayer: playLeftLayer, pauseLayer: pauseLeftLayer)
        animateLayer(playLayer: playRightLayer, pauseLayer: pauseRightLayer)
    }
    
    private func animateLayer(playLayer: CAShapeLayer, pauseLayer: CAShapeLayer) {
      let animation = CABasicAnimation(keyPath: "path")
      
      animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      animation.duration = 0.3
      
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


