//
//   PlayerSwiftUIWrapper.swift
//  Pods
//
//  Created by Michel Gutner on 09/11/24.
//


import SwiftUI
import AVKit

import Foundation
import Combine

class ObservableObjectManager: ObservableObject {
  @Published var isFullscreen: Bool = false
  @Published var thumbnailsDictionary: NSDictionary? = nil
  
  init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleThumbnailsNotification(_:)),
      name: .AVPlayerThumbnails,
      object: nil
    )
  }
  
  @objc private func handleThumbnailsNotification(_ notification: Notification) {
    if let thumbnails = notification.object as? NSDictionary {
      DispatchQueue.main.async {
        self.thumbnailsDictionary = thumbnails
      }
    }
  }
  
  public func clear() {
    thumbnailsDictionary = [:]
    NotificationCenter.default.removeObserver(self, name: .AVPlayerThumbnails, object: nil)
  }
}

struct PlaybackControlsInterface {
  var onTapFullscreen: () -> Void
}

@available(iOS 14.0, *)
class VideoPlayerController : UIViewController {
  public weak var player: AVPlayer?
  public var menus: NSDictionary?
  private var playerLayer : AVPlayerLayer!
  @ObservedObject private var observable = ObservableObjectManager()
  
  private var currentLayerScale: CGFloat = 1.0
  private var initialized: Bool = false
  private var session = AVAudioSession.sharedInstance()
  private var fullscreenVC = UIViewController()
  private let rootVC = UIApplication.shared.windows.first?.rootViewController
  
  private var playbackControls: UIHostingController<OverlayManager>? = nil
  private var isTransitioning: Bool = false

  
  init(player: AVPlayer, menus: NSDictionary?) {
    self.playerLayer = AVPlayerLayer(player: player)
    self.menus = menus
    
    super.init(nibName: nil, bundle: nil)
    self.playerLayer.frame = view.bounds
    view.layer.addSublayer(playerLayer)
    addPlaybackControlsToController(to: self)
    self.addChild(self.playbackControls!)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
    view.addGestureRecognizer(pinchGesture)
    
    playbackControls = UIHostingController(
      rootView:
        OverlayManager(
          player: playerLayer.player,
          scheduleHideControls: {},
          advanceValue: 10,
          suffixAdvanceValue: "seconds",
          onTapOverlay: {
            //            self.playbackVC.toggleController()
          },
          onTapFullscreen: {
            self.toggleFullScreen()
          },
          menus: .constant(menus)
        ))
    initializeAudioSession()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    playerLayer.removeFromSuperlayer()
    playerLayer.player?.replaceCurrentItem(with: nil)
    observable.clear()
  }
  
  @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
    if gesture.state == .changed || gesture.state == .began {
      let scale = gesture.scale
      let newScale = currentLayerScale * scale
      
      if newScale > 1.0 {
        playerLayer.videoGravity = .resizeAspectFill
      } else {
        playerLayer.videoGravity = .resizeAspect
      }
    }
  }
  
  private func initializeAudioSession() {
    do {
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
    }
    catch {}
  }
  
  private func addPlaybackControlsToController(to controller: UIViewController) {
      if let playbackControls {
          if playbackControls.parent != controller {
              playbackControls.willMove(toParent: nil)
              playbackControls.view.removeFromSuperview()
              playbackControls.removeFromParent()
              
              playbackControls.view.backgroundColor = .clear
              controller.addChild(playbackControls)
              controller.view.addSubview(playbackControls.view)
              playbackControls.didMove(toParent: controller)
              
              playbackControls.view.translatesAutoresizingMaskIntoConstraints = false
              NSLayoutConstraint.activate([
                  playbackControls.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
                  playbackControls.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
                  playbackControls.view.topAnchor.constraint(equalTo: controller.view.topAnchor),
                  playbackControls.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
              ])
          }
      }
  }

  @objc func toggleFullScreen() {
    if (!observable.isFullscreen) {
      presentFullscreenController()
    } else {
      dismissFullscreenController()
    }
    
    observable.isFullscreen.toggle()
  }
  
  override func viewWillLayoutSubviews() {
    guard let mainBounds = view.window?.windowScene?.screen.bounds else { return }
    if observable.isFullscreen && !isTransitioning {
      playerLayer.frame = mainBounds
      
    }
    if !isTransitioning && !observable.isFullscreen {
      addPlayerLayerFrameWithSafeArea(view.bounds)
    }
  }
  
  private func addPlayerLayerFrameWithSafeArea(_ frame: CGRect) {
    playerLayer.frame = frame.inset(by: UIEdgeInsets(top: view.safeAreaInsets.top, left: view.safeAreaInsets.left, bottom: view.safeAreaInsets.bottom, right: view.safeAreaInsets.right))
  }
  
  private func getCurrentY() -> CGFloat {
    let currentHeight = view.bounds.height
    return currentHeight.rounded() - currentHeight / 4
  }
  
  private func presentFullscreenController() {
    guard !isTransitioning else { return }
    guard let mainBounds = view.window?.windowScene?.screen.bounds else { return }
    
    isTransitioning = true
    
    fullscreenVC.view.bounds = mainBounds
    fullscreenVC.modalPresentationStyle = .overFullScreen
    
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
    fullscreenVC.view.addGestureRecognizer(pinchGesture)
    
    self.fullscreenVC.view.backgroundColor = .black
    fullscreenVC.view.layer.addSublayer(playerLayer)
    
    if view.window?.windowScene?.interfaceOrientation.isLandscape == true {
      playerLayer.frame = mainBounds
      playerLayer.position = CGPoint(x: mainBounds.midX, y: view.bounds.midY)
    } else {
      UIView.animate(withDuration: 0.5, animations: { [self] in
        self.addPlayerLayerFrameWithSafeArea(mainBounds)
        self.playerLayer.position = CGPoint(x: mainBounds.midX, y: getCurrentY())
      })
    }
    
    rootVC?.present(fullscreenVC, animated: false) {
      UIView.animate(withDuration: 0.5, animations: {
        self.playerLayer.position = CGPoint(x: UIScreen.main.bounds.midX, y: self.fullscreenVC.view.bounds.midY)
      }, completion: { _ in
        self.isTransitioning = false
        self.addPlaybackControlsToController(to: self.fullscreenVC)
      })
    }
  }
  
  private func dismissFullscreenController() {
      isTransitioning = true

      self.playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)

      UIView.animate(withDuration: 0.5, animations: {
          self.fullscreenVC.view.backgroundColor = .clear
      })

      self.fullscreenVC.dismiss(animated: false) {
          self.playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        self.addPlayerLayerFrameWithSafeArea(self.view.bounds)
          self.view.layer.addSublayer(self.playerLayer)
          self.addPlaybackControlsToController(to: self)
          self.isTransitioning = false
      }
  }
}

struct Identifier {
  struct LayerNames {
    static let player = "PlayerLayer"
    static let overlay = "OverlayLayer"
  }

  struct ViewNames {
    static let controlsView = "ControlsView"
  }
}
