//
//  CustomPlayPause.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 11/03/24.
//

import SwiftUI
import AVFoundation
import UIKit
import Combine

struct PlayPauseButtonRepresentable: UIViewRepresentable {
    var action: () -> Void
    var color: CGColor?
    var frame: CGRect
    
    func makeUIView(context: Context) -> PlayPauseButton {
      let button = PlayPauseButton(frame: frame, action: action, color: color)
        return button
    }
    
    func updateUIView(_ uiView: PlayPauseButton, context: Context) {
        // Atualize as propriedades do botão, se necessário
    }
}

class PlayPauseButton: UIButton {
  private var cancellables = Set<AnyCancellable>()
  @ObservedObject private var playbackState = PlaybackManager.shared
  private var action: () -> Void
  private var color: CGColor?
  
  private var playLeftLayer: CAShapeLayer!
  private var playRightLayer: CAShapeLayer!
  private var pauseLeftLayer: CAShapeLayer!
  private var pauseRightLayer: CAShapeLayer!
  
  override var isHighlighted: Bool {
    didSet {
      super.isHighlighted = false
    }
  }
  
  init(frame: CGRect, action: @escaping () -> Void, color: CGColor?) {
    self.action = action
    self.color = color
    super.init(frame: frame)
    setupLayers()
    setupObserver()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupLayers() {
    
    self.backgroundColor = UIColor.black.withAlphaComponent(0.2)
    self.layer.cornerRadius = self.bounds.width
    addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    
    // Criação dos layers
    playLeftLayer = createLayer(path: UIBezierPath.playLeftIcon(bounds: bounds).cgPath)
    playRightLayer = createLayer(path: UIBezierPath.playRightIcon(bounds: bounds).cgPath)
    pauseLeftLayer = createLayer(path: UIBezierPath.pauseLeftIcon(bounds: bounds).cgPath)
    pauseRightLayer = createLayer(path: UIBezierPath.pauseRightIcon(bounds: bounds).cgPath)
    
    updateLayersVisibility()
  }
  
  private func createLayer(path: CGPath) -> CAShapeLayer {
    let layer = CAShapeLayer()
    layer.path = path
    layer.fillColor = color ?? UIColor.white.cgColor
    layer.strokeColor = color ?? UIColor.white.cgColor
    layer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    self.layer.addSublayer(layer)
    return layer
  }
  
  @objc private func buttonTapped() {
    action()
  }
  
  private func setupObserver() {
    playbackState.$isPlaying
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.animateLayerTransition()
      }.store(in: &cancellables)
  }
  
  private func animateLayerTransition() {
    let animation = CABasicAnimation(keyPath: "path")
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    animation.duration = 0.5
    
    if playbackState.isPlaying {
      applyAnimation(animation, from: playLeftLayer, to: pauseLeftLayer)
      applyAnimation(animation, from: playRightLayer, to: pauseRightLayer)
    } else {
      applyAnimation(animation, from: pauseLeftLayer, to: playLeftLayer)
      applyAnimation(animation, from: pauseRightLayer, to: playRightLayer)
    }
    
    updateLayersVisibility()
  }
  
  private func updateLayersVisibility() {
    let isPlaying = playbackState.isPlaying
    
    playLeftLayer.isHidden = isPlaying
    playRightLayer.isHidden = isPlaying
    pauseLeftLayer.isHidden = !isPlaying
    pauseRightLayer.isHidden = !isPlaying
  }
  
  private func applyAnimation(_ animation: CABasicAnimation, from fromLayer: CAShapeLayer, to toLayer: CAShapeLayer) {
    animation.fromValue = fromLayer.path
    animation.toValue = toLayer.path
    fromLayer.add(animation, forKey: "path")
    toLayer.add(animation, forKey: "path")
  }
}

