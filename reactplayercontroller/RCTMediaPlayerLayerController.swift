//
//  RCTMediaPlayerPlayerController.swift
//  DoubleConversion
//
//  Created by Michel Gutner on 10/01/25.
//

import Foundation
import AVFoundation
import UIKit

public enum RCTLayerManagerActionType {
  case pinchToZoom
  case fullscreen
}

public protocol RCTMediaPlayerLayerManagerProtocol: AnyObject {
  func playerLayerControlView(_ playerLayer: RCTMediaPlayerLayerController, didRequestControl action: RCTLayerManagerActionType, didChangeState state: Any?)
}

open class RCTMediaPlayerLayerController : UIViewController {
  fileprivate var playerLayer = MediaPlayerLayerManager()
  fileprivate var fullscreenController = UIViewController()
  open weak var delegate: RCTMediaPlayerLayerManagerProtocol?
  
  fileprivate var rootVC = UIApplication.shared.windows.first?.rootViewController
  fileprivate var isFullscreen: Bool = false
  fileprivate var isFullscreenTransition: Bool = false
  fileprivate let currentZoomScale: CGFloat = 1.0
  
  fileprivate weak var contentOverlayController: UIViewController?
  
  init (player: AVPlayer) {
    super.init(nibName: nil, bundle: nil)
    playerLayer.attachPlayer(with: player)
    self.view.layer.addSublayer(playerLayer)
    
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
    view.addGestureRecognizer(pinchGesture)
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func viewWillLayoutSubviews() {
    guard let mainBounds = view.window?.windowScene?.screen.bounds else { return }

    if isFullscreen && !isFullscreenTransition {
      playerLayer.frame = mainBounds
    }
    
    if !isFullscreenTransition && !isFullscreen {
      attachPlayerLayerWithSafeArea(view.bounds)
    }
  }
  
  open func prepareToDeInit() {
    playerLayer.detachPlayer()
  }
  
  open func addContentOverlayController(with controller: UIViewController) {
    self.contentOverlayController = controller
    didMoveControlsToParent(to: self)
  }
  
  open func didPresentFullscreen() {
    guard !isFullscreenTransition else { return }
    guard let mainBounds = self.view?.window?.windowScene?.screen.bounds else { return }
    isFullscreenTransition = true
    
    fullscreenController.view.bounds = mainBounds
    fullscreenController.modalPresentationStyle = .overFullScreen
    
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
    fullscreenController.view.addGestureRecognizer(pinchGesture)
    
    self.fullscreenController.view.backgroundColor = .black
    fullscreenController.view.layer.addSublayer(playerLayer)
    
    if self.view.window?.windowScene?.interfaceOrientation.isLandscape == true {
      playerLayer.frame = mainBounds
      playerLayer.position = CGPoint(x: mainBounds.midX, y: self.view.bounds.midY)
    } else {
      UIView.animate(withDuration: 0.5, animations: { [self] in
        self.attachPlayerLayerWithSafeArea(mainBounds)
        self.playerLayer.position = CGPoint(x: mainBounds.midX, y: calculateCurrentOffsetY())
      })
    }
    
    rootVC?.present(fullscreenController, animated: false) {
      UIView.animate(withDuration: 0.5, animations: {
        self.playerLayer.position = CGPoint(x: UIScreen.main.bounds.midX, y: self.fullscreenController.view.bounds.midY)
      }, completion: { [self] _ in
        self.delegate?.playerLayerControlView(self, didRequestControl: .fullscreen, didChangeState: true)
        self.isFullscreen = true
        isFullscreenTransition = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
          if let contentOverlayController {
            contentOverlayController.willMove(toParent: nil)
            contentOverlayController.view.removeFromSuperview()
            contentOverlayController.removeFromParent()
            
            contentOverlayController.view.backgroundColor = .clear
            fullscreenController.addChild(contentOverlayController)
            fullscreenController.view.addSubview(contentOverlayController.view)
            contentOverlayController.didMove(toParent: fullscreenController)
            
            contentOverlayController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
              contentOverlayController.view.leadingAnchor.constraint(equalTo: fullscreenController.view.leadingAnchor),
              contentOverlayController.view.trailingAnchor.constraint(equalTo: fullscreenController.view.trailingAnchor),
              contentOverlayController.view.topAnchor.constraint(equalTo: fullscreenController.view.topAnchor),
              contentOverlayController.view.bottomAnchor.constraint(equalTo: fullscreenController.view.bottomAnchor)
            ])
          }
        }
        
      })
    }
  }
  
  open func didDismissFullscreen() {
    isFullscreenTransition = true

    playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)

    UIView.animate(withDuration: 0.5, animations: {
        self.fullscreenController.view.backgroundColor = .clear
    })
      
    self.fullscreenController.dismiss(animated: false) { [self] in
    playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
    self.attachPlayerLayerWithSafeArea(self.view.bounds)
    self.view.layer.addSublayer(playerLayer)
    self.didMoveControlsToParent(to: self)
    self.isFullscreenTransition = false
    self.isFullscreen = false
      self.delegate?.playerLayerControlView(self, didRequestControl: .fullscreen, didChangeState: false)
  }
}
  
  @objc fileprivate func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
    guard gesture.numberOfTouches >= 2 else { return }
    
    let touch1 = gesture.location(ofTouch: 0, in: view)
    let touch2 = gesture.location(ofTouch: 1, in: view)
    let minZoom = 1.0
    let maxZoom = 2.0

    let isHorizontal = abs(touch1.x - touch2.x) > abs(touch1.y - touch2.y)

    if gesture.state == .changed || gesture.state == .began {
      let scale = gesture.scale
      var newScale = currentZoomScale * scale
      
      newScale = max(minZoom, min(newScale, maxZoom))
      
      if isHorizontal {
        if (newScale > 1) {
          playerLayer.videoGravity = .resize
//          NotificationCenter.default.post(name: .EventPinchZoom, object: nil, userInfo: ["currentZoom": "resize"])
          self.delegate?.playerLayerControlView(self, didRequestControl: .fullscreen, didChangeState: ["currentZoom": "resize"])
          return;
        }
      } else {
        if (newScale > 1) {
          playerLayer.videoGravity = .resizeAspectFill
          self.delegate?.playerLayerControlView(self, didRequestControl: .fullscreen, didChangeState: ["currentZoom": "resizeAspectFill"])
          return;
        }
      }
      playerLayer.videoGravity = .resizeAspect
      
      self.delegate?.playerLayerControlView(self, didRequestControl: .fullscreen, didChangeState: ["currentZoom": "resizeAspect"]) 
    }
  }
  
  fileprivate func attachPlayerLayerWithSafeArea(_ frame: CGRect) {
    playerLayer.frame = frame.inset(
      by: UIEdgeInsets(
        top: self.view.safeAreaInsets.top,
        left: self.view.safeAreaInsets.left,
        bottom: self.view.safeAreaInsets.bottom,
        right: self.view.safeAreaInsets.right
      )
    )
  }
  
  fileprivate func calculateCurrentOffsetY() -> CGFloat {
    let currentHeight = view.bounds.height
    return currentHeight.rounded() - currentHeight / 4
  }
  
  fileprivate func didMoveControlsToParent(to controller: UIViewController) {
      if let contentOverlayController {
          if contentOverlayController.parent != controller {
            contentOverlayController.removeFromParent()

            contentOverlayController.view.backgroundColor = .clear
              controller.view.addSubview(contentOverlayController.view)
            contentOverlayController.didMove(toParent: self)

            contentOverlayController.view.translatesAutoresizingMaskIntoConstraints = false
              NSLayoutConstraint.activate([
                contentOverlayController.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
                contentOverlayController.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
                contentOverlayController.view.topAnchor.constraint(equalTo: controller.view.topAnchor),
                contentOverlayController.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
              ])
          }
      }
  }
}
