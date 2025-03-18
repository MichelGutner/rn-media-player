//
//  Modal.swift
//  Pods
//
//  Created by Michel Gutner on 23/02/25.
//

import SwiftUI
import UIKit
import AVKit

public protocol MenuOptionsControlViewDelegate : AnyObject {
  func onMenuOptionSelected(option: EMenuOptionItem, name: String, value: Any)
}

class MenuOptionsControlView: UIView {
  weak var player: AVPlayer?
  fileprivate var isPresented: Bool = false
  fileprivate var controller: UIHostingController<MenuOptionsContentView>?
  fileprivate var overlayWindow: UIWindow?
  fileprivate var menuOptionsDictionary: NSDictionary = [:]
  fileprivate var menuItems: [MenuItem] = []
  fileprivate var selectedOptions: [SelectedOption] = []
  public var delegate: MenuOptionsControlViewDelegate?
  
  
  open var selectionGroup: AVMediaSelectionGroup?
  
  public init(player: AVPlayer? = nil) {
    super.init(frame: .zero)
    self.player = player
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
      menuItems: Binding(get: {
        self.menuItems
      }, set: { newValue in
        self.menuItems = newValue
        }),
      selectedOptions: Binding(get: {
        self.selectedOptions
      }, set: { newValue in
        self.selectedOptions = newValue
        }),
      onMenuItemSelected: { [weak self] option, name, value in
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
        
        self?.delegate?.onMenuOptionSelected(option: transformedOption, name: name, value: value)
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
  
  func createOptions(with dictionary: NSDictionary) {
    dictionary.allKeys.forEach { key in
      guard let keyString = key as? String,
            let values = dictionary[key] as? NSDictionary,
            let optionsArray = values["options"] as? [NSDictionary],
            let title = values["title"] as? String else { return }
      let initialSelection = values["initialOptionSelected"] ?? optionsArray.first!["name"] as! String
      let isDisabled = values["disabled"] as? Bool ?? false
      
      let icon: String
      switch keyString {
      case "speeds":
        icon = "timer"
      case "qualities":
        icon = "text.word.spacing"
      default:
        icon = "questionmark.circle"
      }
      
      let options = optionsArray.compactMap { dict -> MenuOption? in
        guard let name = dict["name"] as? String, let value = dict["value"] else { return nil }
        selectedOptions.append(SelectedOption(parentTitle: title, selectedOption: initialSelection as! String))
        return MenuOption(id: keyString, name: name, value: value, selected: initialSelection as! String)
      }
      
      if !isDisabled {
        self.menuItems.append(MenuItem(id: keyString, title: title, icon: icon, options: options))
      }
    }
        
    let captions = dictionary["captions"] as! NSDictionary
    extractSelectionOptionsFromAsset(with: captions)
  }

  open func extractSelectionOptionsFromAsset(with captions: NSDictionary) {
    let tagId = "captions"
    let disabledCaptionName = captions["disabledCaptionName"] as! String
    let titleText = captions["title"] as! String
    let disabled = captions["disabled"] as! Bool
    
    guard let asset = player?.currentItem?.asset else {
      return
    }
    
    var selectionOption: [AVMediaSelectionOption] = []
    
    asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
      DispatchQueue.main.async { [self] in
        if let legibleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
          self.selectionGroup = legibleGroup
          for option in legibleGroup.options {
            selectionOption.append(option)
          }
          var data = [disabledCaptionName]
          selectionOption.forEach { data.append($0.displayName) }
          
          let newOptions = data.map { caption in
            MenuOption(
              id: tagId,
              name: caption,
              value: caption == disabledCaptionName ? nil : selectionOption.first(where: { $0.displayName == caption }),
              selected: disabledCaptionName
            )
          }
          if !disabled {
            selectedOptions.append(SelectedOption(parentTitle: titleText, selectedOption: disabledCaptionName))
            self.menuItems.append(MenuItem(id: tagId, title: titleText, icon: "captions.bubble", options: newOptions))
          }
        }
      }
    }
  }
}
