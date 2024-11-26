//
//  CustomSeekSlider.swift
//  Pods
//
//  Created by Michel Gutner on 25/11/24.
//


import UIKit
import AVFoundation

class MediaSeekSlider: UIView {
  private let backgroundBar = UIView()
  private let bufferingBar = UIView()
  private let progressBar = UIView()
  private let thumbView = UIView()
  
  var bufferingProgress: CGFloat = 0 {
    didSet { updateBufferingBar() }
  }
  var sliderProgress: CGFloat = 0 {
    didSet { updateProgressBar() }
  }
  
  var onProgressChanged: ((CGFloat) -> Void)?
  var onProgressEnded: ((CGFloat) -> Void)?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
    addPanGesture()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupViews()
    addPanGesture()
  }
  
  private func setupViews() {
    backgroundBar.backgroundColor = .systemFill
    backgroundBar.layer.cornerRadius = 6
    backgroundBar.clipsToBounds = true
    addSubview(backgroundBar)
    
    bufferingBar.backgroundColor = .secondarySystemFill
    backgroundBar.addSubview(bufferingBar)
    
    progressBar.backgroundColor = .white
    backgroundBar.addSubview(progressBar)
    
    thumbView.backgroundColor = .white.withAlphaComponent(0.0001)
    thumbView.frame.size = CGSize(width: 30, height: 30)
    thumbView.layer.cornerRadius = thumbView.bounds.width / 2
    addSubview(thumbView)
    thumbView.layer.zPosition = 10
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    backgroundBar.frame = CGRect(x: 0, y: bounds.midY, width: bounds.width, height: 10)
    bufferingBar.frame = CGRect(x: 0, y: 0, width: bufferingProgress * bounds.width, height: bounds.height)
    progressBar.frame = CGRect(x: 0, y: 0, width: sliderProgress * bounds.width, height: bounds.height)
    
    let thumbX = sliderProgress * bounds.width
    thumbView.center = CGPoint(x: max(thumbX, thumbView.bounds.width / 2), y: bounds.height / 2 + 5)
    bringSubviewToFront(thumbView)
  }
  
  private func addPanGesture() {
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    thumbView.addGestureRecognizer(panGesture)
  }
  
  @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
    let location = gesture.location(in: self)
    let progress = max(0, min(location.x / bounds.width, 1))
    
    switch gesture.state {
    case .changed:
      sliderProgress = progress
      onProgressChanged?(sliderProgress)
    case .ended:
      sliderProgress = progress
      onProgressEnded?(sliderProgress)
    default:
      break
    }
  }
  
  private func updateBufferingBar() {
    bufferingBar.frame.size.width = bufferingProgress * bounds.width
  }
  
  private func updateProgressBar() {
    progressBar.frame.size.width = sliderProgress * bounds.width
    setNeedsLayout()
  }
}
