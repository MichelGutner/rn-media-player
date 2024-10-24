//
//  CustomPlayPause.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 11/03/24.
//

import AVFoundation
import UIKit

class PlayPauseButton: UIButton {
    private var action: () -> Void
    private var color: CGColor?
    private var playLeftLayer: CAShapeLayer!
    private var playRightLayer: CAShapeLayer!
    
    private var pauseLeftLayer: CAShapeLayer!
    private var pauseRightLayer: CAShapeLayer!
    
    private var playing: Bool = false {
        didSet {
            updateLayersVisibility()
        }
    }
    
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
        setupObservers()
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
    
    private func updateLayersVisibility() {
        playLeftLayer.isHidden = playing
        playRightLayer.isHidden = playing
        pauseLeftLayer.isHidden = !playing
        pauseRightLayer.isHidden = !playing
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleSeekingNotification(_:)), name: .SeekingNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDoubleTapNotification(_:)), name: .DoubleTapNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleLoadingNotification(_:)), name: .AVPlayerInitialLoading, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlayToEndNotification(_:)), name: AVPlayerItem.didPlayToEndTimeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlaybackStatusNotification(_:)), name: .AVPlayerTimeControlStatus, object: nil)
    }
    
    @objc private func buttonTapped() {
        action()
        playing.toggle()
        animateLayerTransition()
    }
    
    private func animateLayerTransition() {
        let animation = CABasicAnimation(keyPath: "path")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.duration = 0.5
        
        if playing {
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
    
    @objc private func handleSeekingNotification(_ notification: Notification) {
        guard let isSeeking = notification.object as? Bool else { return }
        self.isHidden = isSeeking
    }
    
    @objc private func handleDoubleTapNotification(_ notification: Notification) {
        guard let isDoubleTapped = notification.object as? Bool else { return }
        self.isHidden = isDoubleTapped
    }
    
    @objc private func handleLoadingNotification(_ notification: Notification) {
        guard let isLoading = notification.object as? Bool else { return }
        UIView.animate(withDuration: 0.1) {
            self.isHidden = isLoading
        }
    }
    
    @objc private func handlePlayToEndNotification(_ notification: Notification) {
        self.isHidden = true
    }
    
    @objc private func handlePlaybackStatusNotification(_ notification: Notification) {
        guard let isPlaying = notification.object as? Bool else { return }
        playing = isPlaying
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
