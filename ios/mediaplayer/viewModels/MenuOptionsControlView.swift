//
//  Modal.swift
//  Pods
//
//  Created by Michel Gutner on 23/02/25.
//

import SwiftUI
import UIKit

public protocol MenuOptionsControlViewDelegate : AnyObject {
  func onMenuOptionSelected(option: EMenuOptionItem, value: Any)
}

class MenuOptionsControlView: UIView {
  fileprivate var isPresented: Bool = false
  fileprivate var controller: UIHostingController<MenuOptionsContentView>?
  fileprivate var overlayWindow: UIWindow?
  fileprivate var menuOptionsDictionary: NSDictionary = [:]
  public var delegate: MenuOptionsControlViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    updateLayout()
    setupLayout()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    updateLayout()
  }
  
  private func setupLayout() {
    controller = UIHostingController(rootView: MenuOptionsContentView(
      isMenuVisible: Binding(
        get: { self.isPresented },
        set: { newValue in
          self.isPresented = newValue
          if !newValue { self.dismiss() }
        }
      ),
      menuData: Binding(get: {
        self.menuOptionsDictionary
      }, set: { newValue in
        self.menuOptionsDictionary = newValue
        }),
      onMenuItemSelected: { [weak self] option, value in
        let transformedOption: EMenuOptionItem = {
          switch option {
          case "speeds":
            return .speeds
          case "qualities":
            return .qualities
          case "captions":
            return .captions
          default:
            return .unkown
          }
        }()
        
        self?.delegate?.onMenuOptionSelected(option: transformedOption, value: value)
      }
      )
    )
    
    controller?.view.backgroundColor = .clear
    if let controller {
      addSubview(controller.view)
    }
  }
  
  private func updateLayout() {
    guard let window = UIApplication.shared.windows.first else { return }
    frame = window.bounds
    
    controller?.view.frame = bounds
  }
  
  func present() {
    guard !isPresented else { return }
    isPresented = true
    
    if let currentWindow = UIApplication.shared.windows.first {
      let overlayWindow = UIWindow(frame: currentWindow.bounds)
      overlayWindow.windowScene = currentWindow.windowScene
      overlayWindow.rootViewController = UIViewController()
      UIView.animate(withDuration: 0.2) {
        overlayWindow.backgroundColor = .black.withAlphaComponent(0.15)
      }
      overlayWindow.windowLevel = .alert + 100
      overlayWindow.isHidden = false
      
      self.overlayWindow = overlayWindow
      overlayWindow.addSubview(self)
      
      updateLayout()
    }
  }

  func dismiss() {
    isPresented = false
    self.overlayWindow?.isHidden = true
    self.overlayWindow?.removeFromSuperview()
    self.overlayWindow = nil
  }
  
  func setMenuOptions(with dictionary: NSDictionary) {
    self.menuOptionsDictionary = dictionary
  }
}
