//
//   VideoPlayerViewController.swift
//  Pods
//
//  Created by Michel Gutner on 09/11/24.
//


import SwiftUI
import AVKit
import Combine

@available(iOS 14.0, *)
class VideoPlayerViewController : UIViewController {
  public var mediaSessionManager: MediaSessionManager
  public weak var player: AVPlayer?
  public var menus: NSDictionary?
  private var playerLayer : AVPlayerLayer!
  
  private var currentZoomScale: CGFloat = 1.0
  private var audioSession = AVAudioSession.sharedInstance()
  private var fullscreenVC = UIViewController()
  private let rootVC = UIApplication.shared.windows.first?.rootViewController
  
  private var mediaPlayerHC: UIHostingController<MediaPlayerControlsView>? = nil
  private var isFullscreenTransitionActive: Bool = false

  
  init(player: AVPlayer, mediaSession: MediaSessionManager, menus: NSDictionary?) {
    self.mediaSessionManager = mediaSession
    self.playerLayer = AVPlayerLayer(player: player)
    self.menus = menus
    
    super.init(nibName: nil, bundle: nil)
    mediaSession.player = player
    
    self.playerLayer.frame = view.bounds
    attachControlsToParent(to: self)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
    view.addGestureRecognizer(pinchGesture)
    view.layer.addSublayer(playerLayer)
    mediaPlayerHC = UIHostingController(
      rootView:
        MediaPlayerControlsView(
          mediaSession: mediaSessionManager,
          advanceValue: 10,
          suffixAdvanceValue: "seconds",
          onTapFullscreen: {
            self.toggleFullScreen()
          },
          menus: .constant(menus)
        ))
    
    configureAudioSession()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    releaseResources()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  public func releaseResources() {
      playerLayer.removeFromSuperlayer()
      playerLayer.player?.replaceCurrentItem(with: nil)
      mediaPlayerHC?.view.removeFromSuperview()
      mediaPlayerHC?.removeFromParent()
      self.view.removeFromSuperview()
      self.removeFromParent()
      mediaSessionManager.clear()
  }
  
  @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
    if gesture.state == .changed || gesture.state == .began {
      let scale = gesture.scale
      let newScale = currentZoomScale * scale
      
      if newScale > 1.0 {
        playerLayer.videoGravity = .resizeAspectFill
      } else {
        playerLayer.videoGravity = .resizeAspect
      }
    }
  }
  
  private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error.localizedDescription)")
        }
  }
  
  private func attachControlsToParent(to controller: UIViewController) {
      if let mediaPlayerHC {
          if mediaPlayerHC.parent != controller {
              mediaPlayerHC.removeFromParent()

              mediaPlayerHC.view.backgroundColor = .clear
              controller.view.addSubview(mediaPlayerHC.view)
              mediaPlayerHC.didMove(toParent: self)

              mediaPlayerHC.view.translatesAutoresizingMaskIntoConstraints = false
              NSLayoutConstraint.activate([
                  mediaPlayerHC.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
                  mediaPlayerHC.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
                  mediaPlayerHC.view.topAnchor.constraint(equalTo: controller.view.topAnchor),
                  mediaPlayerHC.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
              ])
          }
      }
  }

  @objc func toggleFullScreen() {
    mediaSessionManager.isFullscreen ? exitFullscreenMode() : enterFullscreenMode()
            mediaSessionManager.isFullscreen.toggle()
  }
  
  override func viewWillLayoutSubviews() {
    guard let mainBounds = view.window?.windowScene?.screen.bounds else { return }
    if mediaSessionManager.isFullscreen && !isFullscreenTransitionActive {
      playerLayer.frame = mainBounds
      
    }
    if !isFullscreenTransitionActive && !mediaSessionManager.isFullscreen {
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
  
  private func enterFullscreenMode() {
    guard !isFullscreenTransitionActive else { return }
    guard let mainBounds = view.window?.windowScene?.screen.bounds else { return }
    mediaSessionManager.isControlsVisible = false
    isFullscreenTransitionActive = true
    
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
      }, completion: { [self] _ in
        isFullscreenTransitionActive = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
          if let mediaPlayerHC {
            mediaPlayerHC.willMove(toParent: nil)
            mediaPlayerHC.view.removeFromSuperview()
            mediaPlayerHC.removeFromParent()
            
            mediaPlayerHC.view.backgroundColor = .clear
            fullscreenVC.addChild(mediaPlayerHC)
            fullscreenVC.view.addSubview(mediaPlayerHC.view)
            mediaPlayerHC.didMove(toParent: fullscreenVC)
            
            mediaPlayerHC.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
              mediaPlayerHC.view.leadingAnchor.constraint(equalTo: fullscreenVC.view.leadingAnchor),
              mediaPlayerHC.view.trailingAnchor.constraint(equalTo: fullscreenVC.view.trailingAnchor),
              mediaPlayerHC.view.topAnchor.constraint(equalTo: fullscreenVC.view.topAnchor),
              mediaPlayerHC.view.bottomAnchor.constraint(equalTo: fullscreenVC.view.bottomAnchor)
            ])
          }
        }
      })
    }
  }
  
  private func exitFullscreenMode() {
      isFullscreenTransitionActive = true

      self.playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)

      UIView.animate(withDuration: 0.5, animations: {
          self.fullscreenVC.view.backgroundColor = .clear
      })
        
    self.fullscreenVC.dismiss(animated: false) {
      self.playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
      self.addPlayerLayerFrameWithSafeArea(self.view.bounds)
      self.view.layer.addSublayer(self.playerLayer)
      self.attachControlsToParent(to: self)
      self.isFullscreenTransitionActive = false
    }
  }
}