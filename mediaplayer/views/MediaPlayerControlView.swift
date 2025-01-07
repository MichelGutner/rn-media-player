//
//  MediaPlayerControlView.swift
//  Pods
//
//  Created by Michel Gutner on 04/01/25.
//

import UIKit
import SwiftUI
import AVFoundation

public enum MediaPlayerControlButtonType {
  case playPause
  case fullscreen
  case optionsMenu
}


public enum MediaPlayerControlActionState : Int {
  case fullscreenActive = 0
  case fullscreenInactive = 1
}

@available(iOS 14.0, *)
public protocol MediaPlayerControlViewDelegate: AnyObject {
  func controlView(_ controlView: MediaPlayerControlView, didButtonPressed button: MediaPlayerControlButtonType, actionState: MediaPlayerControlActionState?, actionValues: Any?)
  func controlView(_ controlView: MediaPlayerControlView, didChangeFrom fromValue: Double, didChangeTo toValue: CMTime)
}

@available(iOS 14.0, *)
open class MediaPlayerControlView: UIViewController {
  fileprivate var uiViewController: UIHostingController<MediaPlayerControlsView>!
  @ObservedObject var observable: MediaPlayerObservable
  open weak var delegate: MediaPlayerControlViewDelegate?
  var mediaPlayerAdapter: MediaPlayerAdapterView?
  fileprivate var fullscreenVC = UIViewController()
  fileprivate var rootVC = UIApplication.shared.windows.first?.rootViewController
  
  fileprivate var isFullscreen: Bool = false
  fileprivate var isFullscreenTransition: Bool = false
  
  init (observable: MediaPlayerObservable) {
    self.observable = observable
    super.init(nibName: nil, bundle: nil)
    setupUI()
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func viewDidDisappear(_ animated: Bool) {
    uiViewController.view.removeFromSuperview()
    uiViewController.removeFromParent()
    fullscreenVC.removeFromParent()
    delegate = nil
  }
  
  open override func viewWillLayoutSubviews() {
    guard let mainBounds = view.window?.windowScene?.screen.bounds else { return }

    if isFullscreen && !isFullscreenTransition {
      self.mediaPlayerAdapter?.playerLayer?.frame = mainBounds
    }
    
    if !isFullscreenTransition && !isFullscreen {
      addPlayerLayerFrameWithSafeArea(view.bounds)
    }
  }
  
  fileprivate func setupUI() {
    var rootControlsView = MediaPlayerControlsView(
      player: mediaPlayerAdapter?.player,
      menus: .constant([:]),
      observable: observable,
      onPlayPause: { [weak self] in
        guard let self = self else { return }
        self.delegate?.controlView(self, didButtonPressed: .playPause, actionState: nil, actionValues: nil)
      }
    )
    rootControlsView.delegate = self
    
    uiViewController = UIHostingController(rootView: rootControlsView)
    didMoveControlsToParent(to: self)
  }
  
  fileprivate func toggleFullscreenMode() {
    if isFullscreen {
      didDismissFullscreenMode()
      delegate?.controlView(self, didButtonPressed: .fullscreen, actionState: .fullscreenInactive, actionValues: nil)
    } else {
      didPresentFullscreenMode()
      delegate?.controlView(self, didButtonPressed: .fullscreen, actionState: .fullscreenActive, actionValues: nil)
    }
  }
  
  func didPresentFullscreenMode() {
    guard !isFullscreenTransition else { return }
    guard let mainBounds = self.view?.window?.windowScene?.screen.bounds else { return }
    guard let playerLayer = mediaPlayerAdapter?.playerLayer else { return }
//    mediaSessionManager.isControlsVisible = false
    isFullscreenTransition = true
    
    fullscreenVC.view.bounds = mainBounds
    fullscreenVC.modalPresentationStyle = .overFullScreen
    
//    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
//    fullscreenVC.view.addGestureRecognizer(pinchGesture)
    
    self.fullscreenVC.view.backgroundColor = .black
    fullscreenVC.view.layer.addSublayer(playerLayer)
    
    if self.view.window?.windowScene?.interfaceOrientation.isLandscape == true {
      playerLayer.frame = mainBounds
      playerLayer.position = CGPoint(x: mainBounds.midX, y: self.view.bounds.midY)
    } else {
      UIView.animate(withDuration: 0.5, animations: { [self] in
        self.addPlayerLayerFrameWithSafeArea(mainBounds)
        self.mediaPlayerAdapter?.playerLayer?.position = CGPoint(x: mainBounds.midX, y: calculateCurrentOffsetY())
      })
    }
    
    rootVC?.present(fullscreenVC, animated: false) {
      UIView.animate(withDuration: 0.5, animations: {
        self.mediaPlayerAdapter?.playerLayer?.position = CGPoint(x: UIScreen.main.bounds.midX, y: self.fullscreenVC.view.bounds.midY)
      }, completion: { [self] _ in
        self.isFullscreen = true
        isFullscreenTransition = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
          if let uiViewController {
            uiViewController.willMove(toParent: nil)
            uiViewController.view.removeFromSuperview()
            uiViewController.removeFromParent()
            
            uiViewController.view.backgroundColor = .clear
            fullscreenVC.addChild(uiViewController)
            fullscreenVC.view.addSubview(uiViewController.view)
            uiViewController.didMove(toParent: fullscreenVC)
            
            uiViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
              uiViewController.view.leadingAnchor.constraint(equalTo: fullscreenVC.view.leadingAnchor),
              uiViewController.view.trailingAnchor.constraint(equalTo: fullscreenVC.view.trailingAnchor),
              uiViewController.view.topAnchor.constraint(equalTo: fullscreenVC.view.topAnchor),
              uiViewController.view.bottomAnchor.constraint(equalTo: fullscreenVC.view.bottomAnchor)
            ])
          }
        }
      })
    }
  }
  
  func didDismissFullscreenMode() {
    guard let playerLayer = mediaPlayerAdapter?.playerLayer! else { return }
    isFullscreenTransition = true

    playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)

    UIView.animate(withDuration: 0.5, animations: {
        self.fullscreenVC.view.backgroundColor = .clear
    })
      
  self.fullscreenVC.dismiss(animated: false) {
    playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
    self.addPlayerLayerFrameWithSafeArea(self.view.bounds)
    self.view.layer.addSublayer(playerLayer)
    self.didMoveControlsToParent(to: self)
    self.isFullscreenTransition = false
    self.isFullscreen = false
  }
}
  
  fileprivate func addPlayerLayerFrameWithSafeArea(_ frame: CGRect) {
    guard let playerLayer = mediaPlayerAdapter?.playerLayer else { return }
    playerLayer.frame = frame.inset(by: UIEdgeInsets(top: self.view.safeAreaInsets.top, left: self.view.safeAreaInsets.left, bottom: self.view.safeAreaInsets.bottom, right: self.view.safeAreaInsets.right))
  }
  
  fileprivate func calculateCurrentOffsetY() -> CGFloat {
    let currentHeight = view.bounds.height
    return currentHeight.rounded() - currentHeight / 4
  }
  
  fileprivate func didMoveControlsToParent(to controller: UIViewController) {
      if let uiViewController {
          if uiViewController.parent != controller {
            uiViewController.removeFromParent()

            uiViewController.view.backgroundColor = .clear
              controller.view.addSubview(uiViewController.view)
            uiViewController.didMove(toParent: self)

            uiViewController.view.translatesAutoresizingMaskIntoConstraints = false
              NSLayoutConstraint.activate([
                uiViewController.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
                uiViewController.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
                uiViewController.view.topAnchor.constraint(equalTo: controller.view.topAnchor),
                uiViewController.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
              ])
          }
      }
  }
}

@available(iOS 14.0, *)
extension MediaPlayerControlView : MediaPlayerControlsViewDelegate {
  public func controlDidTap(_ control: MediaPlayerControlsView, controlType: MediaPlayerControlsViewType, optionMenuSelected option: ((String, Any))) {
    appConfig.log("option \(option)")
    delegate?.controlView(self, didButtonPressed: .optionsMenu, actionState: .none, actionValues: option)
  }
  
  public func sliderDidChange(_ control: MediaPlayerControlsView, didChangeFrom fromValue: Double, didChangeTo toValue: CMTime) {
    appConfig.log("from \(fromValue) to \(toValue.seconds)")
    delegate?.controlView(self, didChangeFrom: fromValue, didChangeTo: toValue)
  }
  
  public func controlDidTap(_ control: MediaPlayerControlsView, controlType: MediaPlayerControlsViewType) {
    switch controlType {
    case .fullscreen:
      toggleFullscreenMode()
    case .playPause:
      delegate?.controlView(self, didButtonPressed: .playPause, actionState: .none, actionValues: nil)
    case .optionsMenu: break
    }
  }
}
