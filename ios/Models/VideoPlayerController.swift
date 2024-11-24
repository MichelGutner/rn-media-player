//
//   PlayerSwiftUIWrapper.swift
//  Pods
//
//  Created by Michel Gutner on 09/11/24.
//


import SwiftUI
import AVKit
import AVFoundation
import Foundation
import Combine
import MediaPlayer

class MediaSessionManager: ObservableObject {
  @Published var player: AVPlayer? = nil
  @Published var isControlsVisible: Bool = true
  @Published var timeoutWorkItem: DispatchWorkItem?
  
  @Published var isFullscreen: Bool = false
  @Published var thumbnailsDictionary: NSDictionary? = nil
  @Published var newRate: Float = 1.0
  @Published var isPlaying: Bool = false

  @Published var isSeeking: Bool = false
  @Published var isFinished: Bool = false
  @Published var currentItemtitle: String? = nil
  
  init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleThumbnailsNotification(_:)),
      name: .AVPlayerThumbnails,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handlePlaybackRate(_:)),
      name: .AVPlayerRateDidChange,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleFinishAVPlayerItem),
      name: AVPlayerItem.didPlayToEndTimeNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(replacePlayerWithNewUrl(_:)),
      name: .AVPlayerUrlChanged,
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
  
  @objc private func handlePlaybackRate(_ notification: Notification) {
    guard let newRate = notification.object as? Float else { return }
    self.newRate = newRate
    DispatchQueue.main.async(execute: { [self] in
      if (self.player?.timeControlStatus == .playing) {
        self.player?.rate = newRate
      }
    })
  }
  
  @objc private func handleFinishAVPlayerItem(_ notification: Notification) {
    guard let _ = notification.object as? AVPlayerItem else { return }
    MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0
    self.isFinished = true
  }
  
  func urlOfCurrentPlayerItem() -> URL? {
    return ((player?.currentItem?.asset) as? AVURLAsset)?.url
  }
  
  @objc private func replacePlayerWithNewUrl(_ notification: Notification) {
    guard let player else { return }
    guard let url = notification.object as? String else { return }
    
    let newUrl = URL(string: url)
    
    if (newUrl == urlOfCurrentPlayerItem()) {
      return
    }
    
    let currentTime = player.currentItem?.currentTime() ?? CMTime.zero
    let asset = AVURLAsset(url: newUrl!)
    let newPlayerItem = AVPlayerItem(asset: asset)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
      player.replaceCurrentItem(with: newPlayerItem)
      player.seek(to: currentTime)
    
      var playerItemStatusObservation: NSKeyValueObservation?
      playerItemStatusObservation = newPlayerItem.observe(\.status, options: [.new]) { (item, _) in
        NotificationCenter.default.post(name: .AVPlayerErrors, object: extractPlayerItemError(item))
        guard item.status == .readyToPlay else {
          return
        }
        playerItemStatusObservation?.invalidate()
      }
    })
  }
  
  func makeNowPlayingInfo() {
    guard let player else { return }
    guard let currentItem = player.currentItem else { return }
    let metadata = currentItem.externalMetadata
    
    currentItemtitle = metadata.first { $0.identifier == .commonIdentifierTitle }?.stringValue ?? nil
    let artist = metadata.first { $0.identifier == .commonIdentifierArtist }?.stringValue ?? "Desconhecido"
    
    let nowPlayingInfo: [String: Any] = [
      MPMediaItemPropertyTitle: currentItemtitle ?? "Sem Título",
        MPMediaItemPropertyArtist: artist,
        MPMediaItemPropertyPlaybackDuration: currentItem.duration.seconds,
        MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
        MPNowPlayingInfoPropertyPlaybackRate: player.rate
    ]
    
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
  
  func updateNowPlayingInfo(time: Double) {
    guard let player = player else { return }
    guard let currentItem = player.currentItem else { return }
    
    let duration = CMTimeGetSeconds(currentItem.duration)
    
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
  
  func setupRemoteCommandCenter() {
    guard let player else { return }
    let commandCenter = MPRemoteCommandCenter.shared()
    
    
    commandCenter.playCommand.addTarget { _ in
      player.play()
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1
      return .success
    }
    
    commandCenter.pauseCommand.addTarget { _ in
      player.pause()
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0
      
      return .success
    }
  }
  
  func toggleControls() {
    withAnimation(.easeInOut(duration: 0.4), {
      isControlsVisible.toggle()
    })
  }
  
  func scheduleHideControls() {
    DispatchQueue.main.async { [self] in
      if let timeoutWorkItem {
        timeoutWorkItem.cancel()
      }
    
      if (isPlaying) {
        self.timeoutWorkItem = .init(block: { [self] in
          withAnimation(.easeInOut(duration: 0.4), {
            isControlsVisible = false
          })
        })
        
        
        if let timeoutWorkItem {
          DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: timeoutWorkItem)
        }
      }
    }
  }
  
  func cancelTimeoutWorkItem() {
    DispatchQueue.main.async { [self] in
      if let timeoutWorkItem {
        timeoutWorkItem.cancel()
      }
    }
  }
  
  func clear() {
  thumbnailsDictionary = [:]
  NotificationCenter.default.removeObserver(self, name: .AVPlayerThumbnails, object: nil)
  NotificationCenter.default.removeObserver(self, name: .AVPlayerUrlChanged, object: nil)
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
  @ObservedObject private var mediaSession = MediaSessionManager()
  
  private var currentLayerScale: CGFloat = 1.0
  private var initialized: Bool = false
  private var session = AVAudioSession.sharedInstance()
  private var fullscreenVC = UIViewController()
  private let rootVC = UIApplication.shared.windows.first?.rootViewController
  
  private var playbackControls: UIHostingController<PlayBackControlsManager>? = nil
  private var isTransitioning: Bool = false

  
  init(player: AVPlayer, menus: NSDictionary?) {
    self.playerLayer = AVPlayerLayer(player: player)
    self.menus = menus
    
    super.init(nibName: nil, bundle: nil)
    
    mediaSession.player = player
    self.playerLayer.frame = view.bounds
    restoreToMainController(to: self)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
    view.addGestureRecognizer(pinchGesture)
    view.layer.addSublayer(playerLayer)
    playbackControls = UIHostingController(
      rootView:
        PlayBackControlsManager(
          mediaSession: mediaSession,
          advanceValue: 10,
          suffixAdvanceValue: "seconds",
          onTapFullscreen: {
            self.toggleFullScreen()
          },
          menus: .constant(menus)
        ))
    
    initializeAudioSession()
    
    mediaSession.makeNowPlayingInfo()
    mediaSession.setupRemoteCommandCenter()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    releaseResources()
  }
  
  public func releaseResources() {
    playerLayer.removeFromSuperlayer()
    playerLayer.player?.replaceCurrentItem(with: nil)
    playbackControls?.view.removeFromSuperview()
    playbackControls?.removeFromParent()
    self.view.removeFromSuperview()
    self.removeFromParent()
    mediaSession.clear()
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
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error.localizedDescription)")
        }
  }
  
  private func restoreToMainController(to controller: UIViewController) {
      if let playbackControls {
          if playbackControls.parent != controller {
              playbackControls.removeFromParent()

              playbackControls.view.backgroundColor = .clear
              controller.view.addSubview(playbackControls.view)
              playbackControls.didMove(toParent: self)

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
    if (!mediaSession.isFullscreen) {
      presentFullscreenController()
    } else {
      dismissFullscreenController()
    }
    
    mediaSession.isFullscreen.toggle()
  }
  
  override func viewWillLayoutSubviews() {
    guard let mainBounds = view.window?.windowScene?.screen.bounds else { return }
    if mediaSession.isFullscreen && !isTransitioning {
      playerLayer.frame = mainBounds
      
    }
    if !isTransitioning && !mediaSession.isFullscreen {
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
      }, completion: { [self] _ in
        isTransitioning = false

        if let playbackControls {
          playbackControls.willMove(toParent: nil)
          playbackControls.view.removeFromSuperview()
          playbackControls.removeFromParent()
          
          playbackControls.view.backgroundColor = .clear
          fullscreenVC.addChild(playbackControls)
          fullscreenVC.view.addSubview(playbackControls.view)
          playbackControls.didMove(toParent: fullscreenVC)
          
          playbackControls.view.translatesAutoresizingMaskIntoConstraints = false
          NSLayoutConstraint.activate([
              playbackControls.view.leadingAnchor.constraint(equalTo: fullscreenVC.view.leadingAnchor),
              playbackControls.view.trailingAnchor.constraint(equalTo: fullscreenVC.view.trailingAnchor),
              playbackControls.view.topAnchor.constraint(equalTo: fullscreenVC.view.topAnchor),
              playbackControls.view.bottomAnchor.constraint(equalTo: fullscreenVC.view.bottomAnchor)
          ])
          
        }
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
      self.restoreToMainController(to: self)
      self.isTransitioning = false
    }
  }
}
