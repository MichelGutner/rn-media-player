//
//  CustomPlayPause.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 11/03/24.
//

import SwiftUI
import AVFoundation
import UIKit

class PlayPauseButton: UIButton {
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
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayers() {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        self.layer.cornerRadius = self.bounds.width
        
        playLeftLayer = createLayer(path: UIBezierPath.playLeftIcon(bounds: bounds).cgPath)
        playRightLayer = createLayer(path: UIBezierPath.playRightIcon(bounds: bounds).cgPath)
        pauseLeftLayer = createLayer(path: UIBezierPath.pauseLeftIcon(bounds: bounds).cgPath)
        pauseRightLayer = createLayer(path: UIBezierPath.pauseRightIcon(bounds: bounds).cgPath)
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
    
    func updateLayersVisibility(observable: ObservableObjectManager) {
        playLeftLayer.isHidden = observable.isPlaying
        playRightLayer.isHidden = observable.isPlaying
        pauseLeftLayer.isHidden = !observable.isPlaying
        pauseRightLayer.isHidden = !observable.isPlaying
    }
    
    @objc private func buttonTapped() {
        action()
    }
    
    public func animateLayerTransition(observable: ObservableObjectManager) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.duration = 0.5

      if observable.isPlaying {
            applyAnimation(animation, from: playLeftLayer, to: pauseLeftLayer)
            applyAnimation(animation, from: playRightLayer, to: pauseRightLayer)
        } else {
            applyAnimation(animation, from: pauseLeftLayer, to: playLeftLayer)
            applyAnimation(animation, from: pauseRightLayer, to: playRightLayer)
        }
    }
    
    private func applyAnimation(_ animation: CABasicAnimation, from fromLayer: CAShapeLayer, to toLayer: CAShapeLayer) {
        animation.fromValue = fromLayer.path
        animation.toValue = toLayer.path
        fromLayer.add(animation, forKey: "path")
        toLayer.add(animation, forKey: "path")
    }
}
