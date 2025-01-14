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
  
  var bufferingProgress: Double = 0 {
    didSet { updateBufferingBar() }
  }
  var sliderProgress: Double = 0 {
    didSet { updateProgressBar() }
  }
  
  var onProgressBegan: ((Double) -> Void)?
  var onProgressChanged: ((Double) -> Void)?
  var onProgressEnded: ((Double) -> Void)?
  
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
    backgroundBar.clipsToBounds = true
    addSubview(backgroundBar)
    
    bufferingBar.backgroundColor = .secondarySystemFill
    backgroundBar.addSubview(bufferingBar)
    
    progressBar.backgroundColor = .white
    backgroundBar.addSubview(progressBar)
    
    thumbView.backgroundColor = .clear
    thumbView.frame.size = CGSize(width: 45, height: 45)
    thumbView.layer.cornerRadius = thumbView.bounds.width / 2
    addSubview(thumbView)
    thumbView.layer.zPosition = 10
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let sliderheight = bounds.height * 0.2
    
    backgroundBar.frame = CGRect(x: 0, y: bounds.midY, width: bounds.width, height: sliderheight)
    bufferingBar.frame = CGRect(x: 0, y: 0, width: bufferingProgress * bounds.width, height: bounds.height)
    progressBar.frame = CGRect(x: 0, y: 0, width: sliderProgress * bounds.width, height: bounds.height)
    
    let thumbX = sliderProgress * bounds.width
    thumbView.center = CGPoint(x: max(thumbX, thumbView.bounds.width / 2), y: sliderheight * 3)
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
    case .began:
      animateTransition { [self] in
        thumbView.backgroundColor = .systemFill
      }
      onProgressBegan?(progress)
    case .changed:
      sliderProgress = progress
      onProgressChanged?(sliderProgress)
    case .ended:
      animateTransition { [self] in
        thumbView.backgroundColor = .clear
      }
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
  
  fileprivate func animateTransition(onAnimate: @escaping () -> Void) {
    UIView.animate(
      withDuration: 0.5,
      delay: 0,
      usingSpringWithDamping: 0.5,
      initialSpringVelocity: 1,
      options: [],
      animations: onAnimate
    )
  }
}
