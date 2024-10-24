//
//  Replay.swift
//  Pods
//
//  Created by Michel Gutner on 24/10/24.
//
import UIKit
import AVKit

class ReplayButton: UIButton {
  var buttonColor: UIColor = .white {
    didSet {
      self.setNeedsDisplay()
    }
  }
  
  var action: (() -> Void)?
  
  init(frame: CGRect, buttonColor: UIColor = .white, action: (() -> Void)?) {
    super.init(frame: frame)
    self.buttonColor = buttonColor
    self.action = action
    setupButton()
    
    NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: .main, using: { notification in
      self.isHidden = false
    })
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupButton()
  }
  
  private func setupButton() {
    self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    self.layer.cornerRadius = self.frame.width / 2
    self.clipsToBounds = true
    
    let image = UIImage(systemName: "gobackward")?.withTintColor(buttonColor, renderingMode: .alwaysOriginal)
    self.setImage(image, for: .normal)
    
    self.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
  }
  
  @objc private func buttonTapped() {
    action?()
    self.isHidden = true
  }
}
