//
//   PlayerSwiftUIWrapper.swift
//  Pods
//
//  Created by Michel Gutner on 09/11/24.
//


import SwiftUI
import AVKit

class ObservableObjectManager: ObservableObject {
  @Published var isFullscreen: Bool = false
}

struct PlaybackControlsInterface {
  var onTapFullscreen: () -> Void
}

@available(iOS 14.0, *)
class VideoPlayerController : UIViewController {
  public weak var player: AVPlayer?
  private var playerLayer : AVPlayerLayer!
  @ObservedObject private var observable = ObservableObjectManager()
  
  private var currentLayerScale: CGFloat = 1.0
  private var initialized: Bool = false
  private var session = AVAudioSession.sharedInstance()
  private var fullscreenVC = UIViewController()
  private let rootVC = UIApplication.shared.windows.first?.rootViewController
  
  private var overlayHostingController = UIViewController()
  private var isTransitioning: Bool = false

  
  init(player: AVPlayer) {
    playerLayer = AVPlayerLayer(player: player)
    super.init(nibName: nil, bundle: nil)
    
    playerLayer.frame = view.bounds
    view.layer.addSublayer(playerLayer)
    addOverlayIfNeeded(to: self)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
    view.addGestureRecognizer(pinchGesture)
    
    initializeAudioSession()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    playerLayer.removeFromSuperlayer()
    playerLayer.player?.replaceCurrentItem(with: nil)
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
  
  private func addOverlayIfNeeded(to controller: UIViewController) {
    let doubleTapToSeek = UIHostingController(
      rootView:
        OverlayManager(
          player: playerLayer.player,
          onTapBackward: { _ in },
          onTapForward: { _ in },
          scheduleHideControls: {},
          advanceValue: 10,
          suffixAdvanceValue: "seconds",
          onTapOverlay: {
//            self.playbackVC.toggleController()
          },
          onTapFullscreen: {
            self.toggleFullScreen()
          }
        ))
    doubleTapToSeek.removeFromParent()
    doubleTapToSeek.view.removeFromSuperview()
    controller.view.subviews.forEach {
      $0.removeFromSuperview()
    }
    controller.view.addSubview(doubleTapToSeek.view)
    
    doubleTapToSeek.view.backgroundColor = .clear
    
    doubleTapToSeek.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      doubleTapToSeek.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
      doubleTapToSeek.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
      doubleTapToSeek.view.topAnchor.constraint(equalTo: controller.view.topAnchor),
      doubleTapToSeek.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
    ])
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
    
    self.view.subviews.forEach {
      $0.removeFromSuperview()
    }
    
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
        self.addOverlayIfNeeded(to: self.fullscreenVC)
      })
    }
  }
  
  private func dismissFullscreenController() {
      isTransitioning = true

      self.playerLayer.frame = self.view.bounds
      self.playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)

      UIView.animate(withDuration: 0.5, animations: {
          self.fullscreenVC.view.backgroundColor = .clear
          self.playerLayer.frame = self.view.bounds
      })

      self.fullscreenVC.dismiss(animated: false) {
          self.playerLayer.removeFromSuperlayer()

          self.playerLayer.frame = self.view.bounds
          self.playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)

          self.view.layer.addSublayer(self.playerLayer)

          self.addOverlayIfNeeded(to: self)
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
