//
//  FullScreen.swift
//  Pods
//
//  Created by Michel Gutner on 04/10/24.
//

import UIKit

class FullScreenButton: UIButton {
  var isFullScreen: Bool = false {
    didSet {
      updateIcon()
    }
  }
  
  var buttonColor: UIColor = .white {
    didSet {
      self.setNeedsDisplay()
    }
  }
  
  var action: (() -> Void)?
  
  init(frame: CGRect, isFullScreen: Bool = false, buttonColor: UIColor = .white, action: (() -> Void)?) {
    super.init(frame: frame)
    self.isFullScreen = isFullScreen
    self.buttonColor = buttonColor
    self.action = action
    setupButton()
    
    NotificationCenter.default.addObserver(forName: .SeekingNotification, object: nil, queue: .main, using: { notification in
      self.isHidden = notification.object as! Bool
    })
    NotificationCenter.default.addObserver(forName: .DoubleTapNotification, object: nil, queue: .main, using: { notification in
      self.isHidden = notification.object as! Bool
    })
    NotificationCenter.default.addObserver(forName: .AVPlayerInitialLoading, object: nil, queue: .main, using: { notification in
      self.isHidden = notification.object as! Bool
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
    
    updateIcon()
    
    self.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
  }
  
  private func updateIcon() {
    let iconName = isFullScreen ? "arrow.down.forward.and.arrow.up.backward" : "arrow.up.left.and.arrow.down.right"
    let image = UIImage(systemName: iconName)?.withTintColor(buttonColor, renderingMode: .alwaysOriginal)
    self.setImage(image, for: .normal)
  }
  
  @objc private func buttonTapped() {
    action?()
  }
}

