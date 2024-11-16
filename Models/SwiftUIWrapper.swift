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
  @Published var showOverlay: Bool = true
}

@available(iOS 14.0, *)
struct OverlayView: View {
    @ObservedObject var observableObjectManager: ObservableObjectManager

    var body: some View {
        ZStack {
            // Fundo preto com opacidade animada
            Color.black
            .opacity(observableObjectManager.showOverlay ? 0.1 : 0)
                .animation(.easeInOut(duration: 0.3), value: observableObjectManager.showOverlay)
                .edgesIgnoringSafeArea(.all)
            
            // Gerenciador de overlay
            OverlayManager(
                onTapBackward: { _ in },
                onTapForward: { _ in },
                scheduleHideControls: {},
                advanceValue: 10,
                suffixAdvanceValue: "seconds",
                onTapOverlay: {
                  observableObjectManager.showOverlay.toggle()
                }
            )
            
            // Botão de tela cheia
            Button(action: {
                observableObjectManager.isFullscreen.toggle()
            }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .padding()
        }
        .onTapGesture {
            observableObjectManager.showOverlay.toggle()
        }
    }
}


@available(iOS 14.0, *)
class RNVideoPlayerUIViewController : UIViewController {
  var playerLayer: AVPlayerLayer
  
  private var initialized: Bool = false
  
  private var session = AVAudioSession.sharedInstance()
  private var fullscreenController = UIViewController()
  @ObservedObject var observableObjectManager = ObservableObjectManager()
  private var cancellable: Any?
  private let rootViewController = UIApplication.shared.windows.first?.rootViewController
  private var overlayHostingController = UIViewController()
  private var mSafeAreaLayoutGuide: CGRect!
  private var isOnViewTransition: Bool = false
  
  init(_ layer: AVPlayerLayer) {
    self.playerLayer = layer
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    addOverlayIfNeeded(to: self)
    initializeAudioSession()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    playerLayer.removeFromSuperlayer()
    playerLayer.player?.replaceCurrentItem(with: nil)
  }
  
  private func initializeAudioSession() {
    do {
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
    }
    catch {}
  }
  
  private func addOverlayIfNeeded(to controller: UIViewController) {
    overlayHostingController.view.backgroundColor = .clear
    
    controller.addChild(overlayHostingController)
    controller.view.addSubview(overlayHostingController.view)
    overlayHostingController.didMove(toParent: controller)
    
    let fullscreenButton = UIButton(type: .system)
    fullscreenButton.setTitle("Fullscreen", for: .normal)
    fullscreenButton.setTitleColor(.white, for: .normal)
    fullscreenButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    fullscreenButton.layer.cornerRadius = 8
    fullscreenButton.translatesAutoresizingMaskIntoConstraints = false
    fullscreenButton.addTarget(self, action: #selector(toggleFullScreen), for: .touchUpInside)
    
    overlayHostingController.view.addSubview(fullscreenButton)
    
    overlayHostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      overlayHostingController.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
      overlayHostingController.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
      overlayHostingController.view.topAnchor.constraint(equalTo: controller.view.topAnchor),
      overlayHostingController.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
    ])
    
    NSLayoutConstraint.activate([
      fullscreenButton.centerYAnchor.constraint(equalTo: overlayHostingController.view.centerYAnchor),
      fullscreenButton.centerXAnchor.constraint(equalTo: overlayHostingController.view.centerXAnchor),
      fullscreenButton.widthAnchor.constraint(equalToConstant: 120),
      fullscreenButton.heightAnchor.constraint(equalToConstant: 40)
    ])
  }
  
  @objc func toggleFullScreen() {
    if (!observableObjectManager.isFullscreen) {
      presentFullscreenController()
    } else {
        self.dismissFullscreenController()
    }
  }
  
  override func viewDidLayoutSubviews() {
    guard let mainBounds = view.window?.windowScene?.screen.bounds else { return }
    if observableObjectManager.isFullscreen {
      playerLayer.frame = mainBounds
    }
    if !isOnViewTransition && !observableObjectManager.isFullscreen {
      playerLayer.frame = view.bounds
    }
  }

  func getCurrentY() -> CGFloat {
    let currentHeight = view.bounds.height
    return currentHeight.rounded() - currentHeight / 4
  }
  
  private func presentFullscreenController() {
    isOnViewTransition = true
    guard let mainBounds = view.window?.windowScene?.screen.bounds else { return }
    fullscreenController.view.bounds = mainBounds
    fullscreenController.modalPresentationStyle = .overFullScreen
    
    if view.window?.windowScene?.interfaceOrientation.isLandscape == true {
      playerLayer.frame = mainBounds
      fullscreenController.view.layer.addSublayer(playerLayer)
      self.playerLayer.position = CGPoint(x: mainBounds.midX, y: view.bounds.midY)
    } else {
      UIView.animate(withDuration: 0.5, animations: { [self] in
        fullscreenController.view.layer.addSublayer(playerLayer)
        self.playerLayer.position = CGPoint(x: mainBounds.midX, y: getCurrentY())
      })
    }
    
    rootViewController?.present(fullscreenController, animated: false) {
      UIView.animate(withDuration: 0.5, animations: {
        self.playerLayer.position = CGPoint(x: UIScreen.main.bounds.midX, y: self.fullscreenController.view.bounds.midY)
        self.fullscreenController.view.backgroundColor = .black
      }, completion: { _ in
        self.observableObjectManager.isFullscreen = true
        self.isOnViewTransition = false
        self.addOverlayIfNeeded(to: self.fullscreenController)
      })
    }
  }
  
  private func dismissFullscreenController() {
    UIView.animate(withDuration: 0.5, animations: { [self] in
      self.playerLayer.videoGravity = .resizeAspect
      self.fullscreenController.view.backgroundColor = .clear
      self.playerLayer.frame = CGRect(x: 0, y: 0, width: playerLayer.frame.width, height: view.bounds.height)
      self.view.layer.addSublayer(self.playerLayer)
      self.playerLayer.position = CGPoint(x: view.bounds.midX, y: getCurrentY())
    })
  
    self.fullscreenController.dismiss(animated: false) {
      UIView.animate(withDuration: 0.5, animations: {
        self.playerLayer.frame = self.view.bounds
        self.playerLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
      }, completion: { _ in
        self.observableObjectManager.isFullscreen = false
        self.addOverlayIfNeeded(to: self)
      })
    }
  }
}

extension UIViewController {}

struct Identifier {
  struct LayerNames {
    static let player = "PlayerLayer"
    static let overlay = "OverlayLayer"
  }

  struct ViewNames {
    static let controlsView = "ControlsView"
  }
}
