import SwiftUI
import AVKit
import AVFoundation

@available(iOS 14.0, *)
struct ViewController: UIViewControllerRepresentable {
  var player: AVPlayer?
  var autoPlay: Bool
  var menus: NSDictionary?
  var bridgeControls: PlayerControls
  var autoOrientationOnFullscreen: Bool
  var autoEnterFullscreenOnLandscape: Bool
  var thumbnails: NSDictionary?
  var tapToSeek: NSDictionary?
  var UIControls: Styles?
  var videoGravity: AVLayerVideoGravity
  
  @State var thumbnailsUIImageFrames: [UIImage] = []
  @State var isFinishedPlaying: Bool = false
  @State private var isStarted: Bool = false
  
  func makeUIViewController(context: Context) -> some UIViewController {
    context.coordinator.cleanup()
    context.coordinator.configureAudioSession()
    let controller = CustomUIViewController()
    
    controller.onDisappear = {
      context.coordinator.cleanup()
    }
    
    DispatchQueue.main.async {
      if let thumbNailsEnabled = thumbnails?["enabled"] as? Bool {
        thumbnailsUIImageFrames.removeAll()
        if let thumbnailsUrl = thumbnails?["url"] as? String, thumbNailsEnabled {
          context.coordinator.generatingThumbnailsFrames(thumbnailsUrl)
        }
      }
    }
    
    context.coordinator.addObservers(to: player)
    context.coordinator.addNotificationObservers()
    
    if autoPlay {
      player?.play()
    }
    
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    let playerViewController = AVPlayerViewController()
    
    
    DispatchQueue.main.async {
      playerViewController.player = player
      playerViewController.showsPlaybackControls = false
      playerViewController.videoGravity = .resizeAspect
      
      if #available(iOS 16.0, *) {
        playerViewController.allowsVideoFrameAnalysis = false
      }
    }
    
    let playerView = playerViewController.view!
    playerView.frame = uiViewController.view.bounds
    playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    
    let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTapOverlayWithGesture(_:)))
    playerViewController.view.addGestureRecognizer(tapGesture)
    
    
    let overlay = UIHostingController(rootView: OverlayManager(
//      onTapBackward: context.coordinator.onBackwardTime,
//      onTapForward: context.coordinator.onForwardTime,
      observable: ObservableObjectManager(),
      scheduleHideControls: context.coordinator.scheduleHideControls,
      advanceValue: tapToSeek?["value"] as? Int ?? 15,
      suffixAdvanceValue: tapToSeek?["suffixLabel"] as? String ?? "seconds",
      menus: .constant([:])
    ))
    
    let fullScreenButton = FullScreenButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40), isFullScreen: false, buttonColor: UIControls?.fullScreen.color ?? .white) {}
    
    let playPauseButton = PlayPauseButton(
      frame: .init(origin: .zero, size: CGSize(width: 30, height: 30)),
      action: {
        context.coordinator.togglePlayback()
      },
      color: UIControls?.playback.color?.cgColor
    )
    
    let replayButton = ReplayButton(
      frame: .init(origin: .zero, size: CGSize(width: 60, height: 60)),
      buttonColor: UIControls?.playback.color ?? .white,
      action: {
        context.coordinator.resetPlaybackStatus()
      }
    )
    
    let menuButton = UIHostingController(
      rootView: Menus(
        options: menus,
        controls: bridgeControls,
        color: UIControls?.menus.color
      )
    )
    
    let seekSlider = UIHostingController(
      rootView: CustomSeekSlider(
        player: player,
        observable: ObservableObjectManager(),

        UIControlsProps: .constant(UIControls),
        cancelTimeoutWorkItem: context.coordinator.cancelTimeoutWorkItem,
        scheduleHideControls: context.coordinator.scheduleHideControls,
        canPlaying: {
          DispatchQueue.main.async { [self] in
            replayButton.isHidden = true
            context.coordinator.scheduleHideControls()
            player?.play()
          }
        }
      )
    )
    
    let loading = UIHostingController(rootView: CustomLoading(color: UIControls?.loading.color))
    
    
    if playerViewController.parent == nil {
      uiViewController.addChild(playerViewController)
      uiViewController.view.addSubview(playerView)
      playerViewController.didMove(toParent: uiViewController)
    }
    
    context.coordinator.addToSubviewAndBringToFront(view: overlay.view, superview: playerViewController.view)
    
    
    fullScreenButton.action = context.coordinator.toggleFullScreen
    
    overlay.view.addSubview(menuButton.view)
    overlay.view.addSubview(fullScreenButton)
    overlay.view.addSubview(seekSlider.view)
    overlay.view.addSubview(playPauseButton)
    overlay.view.addSubview(loading.view)
    overlay.view.addSubview(replayButton)
    
    
    playPauseButton.translatesAutoresizingMaskIntoConstraints = false
    playPauseButton.isHidden = true
    NSLayoutConstraint.activate([
      playPauseButton.centerXAnchor.constraint(equalTo: overlay.view.safeAreaLayoutGuide.centerXAnchor),
      playPauseButton.centerYAnchor.constraint(equalTo: overlay.view.safeAreaLayoutGuide.centerYAnchor),
      playPauseButton.heightAnchor.constraint(equalToConstant: 60),
      playPauseButton.widthAnchor.constraint(equalToConstant: 60)
    ])
    
    replayButton.translatesAutoresizingMaskIntoConstraints = false
    replayButton.isHidden = true
    NSLayoutConstraint.activate([
      replayButton.centerXAnchor.constraint(equalTo: overlay.view.safeAreaLayoutGuide.centerXAnchor),
      replayButton.centerYAnchor.constraint(equalTo: overlay.view.safeAreaLayoutGuide.centerYAnchor),
      replayButton.heightAnchor.constraint(equalToConstant: 60),
      replayButton.widthAnchor.constraint(equalToConstant: 60)
    ])
    
    loading.view.translatesAutoresizingMaskIntoConstraints = false
    loading.view.backgroundColor = .clear
    
    NSLayoutConstraint.activate([
      loading.view.centerXAnchor.constraint(equalTo: overlay.view.safeAreaLayoutGuide.centerXAnchor),
      loading.view.centerYAnchor.constraint(equalTo: overlay.view.safeAreaLayoutGuide.centerYAnchor),
      loading.view.heightAnchor.constraint(equalToConstant: 60),
      loading.view.widthAnchor.constraint(equalToConstant: 60)
    ])
    
    fullScreenButton.translatesAutoresizingMaskIntoConstraints = false
    fullScreenButton.isHidden = true
    
    NSLayoutConstraint.activate([
      fullScreenButton.bottomAnchor.constraint(equalTo: overlay.view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
      fullScreenButton.trailingAnchor.constraint(equalTo: overlay.view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
      fullScreenButton.heightAnchor.constraint(equalToConstant: 40),
      fullScreenButton.widthAnchor.constraint(equalToConstant: 40)
    ])
    
    menuButton.view.translatesAutoresizingMaskIntoConstraints = false
    menuButton.view.backgroundColor = .clear
    
    NSLayoutConstraint.activate([
      menuButton.view.bottomAnchor.constraint(equalTo: fullScreenButton.bottomAnchor),
      menuButton.view.trailingAnchor.constraint(equalTo: fullScreenButton.leadingAnchor, constant: -8),
      menuButton.view.heightAnchor.constraint(equalToConstant: 40),
      menuButton.view.widthAnchor.constraint(equalToConstant: 40)
    ])
    
    seekSlider.view.translatesAutoresizingMaskIntoConstraints = false
    seekSlider.view.backgroundColor = .clear
    
    NSLayoutConstraint.activate([
      seekSlider.view.bottomAnchor.constraint(equalTo: fullScreenButton.topAnchor, constant: -10),
      seekSlider.view.leadingAnchor.constraint(equalTo: overlay.view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      seekSlider.view.trailingAnchor.constraint(equalTo: overlay.view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
    ])
    
    context.coordinator.player = player
    context.coordinator.parentController = uiViewController
    context.coordinator.playerView = playerView
    context.coordinator.playerViewController = playerViewController
    context.coordinator.overlay = overlay.view
    context.coordinator.fullScreenButton = fullScreenButton
    context.coordinator.autoOrientationOnFullscreen = autoOrientationOnFullscreen
    context.coordinator.autoEnterFullscreenOnLandscape = autoEnterFullscreenOnLandscape
    context.coordinator.thumbnailsUIImageFrames = thumbnailsUIImageFrames
    context.coordinator.loading = loading.view
    context.coordinator.playPauseButton = playPauseButton
  }
  
  class Coordinator: NSObject {
    var player: AVPlayer!
    var parentController: UIViewController?
    var playerView: UIView!
    var playerViewController: AVPlayerViewController!
    var fullScreenController: UIViewController?
    var overlay: UIView!
    var fullScreenButton: FullScreenButton?
    var playPauseButton: PlayPauseButton?
    var autoOrientationOnFullscreen: Bool = false
    var autoEnterFullscreenOnLandscape: Bool = false
    var controlsVisible: Bool = true
    var thumbnailsUIImageFrames: [UIImage] = []
    var timeoutWorkItem: DispatchWorkItem?
    var loading: UIView!
    
    private var originalFrame: CGRect?
    private var isFullScreen: Bool = false
    private var oldTimeControlStatusOnBackground: AVPlayer.TimeControlStatus = .paused
    private var playerItemContext = 0
    private var rate: Float = 1.0
    
    private var session = AVAudioSession.sharedInstance()
    private var isObserveAdded = false
  
    func addObservers(to player: AVPlayer?) {
      guard let player = player else { return }
      player.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.old, .new], context: nil)
      player.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
      isObserveAdded = true
//      player.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
//      player.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
//      player.currentItem?.addObserver(self, forKeyPath: "playbackBufferFull", options: .new, context: nil)
    }
    
    func cleanup() {
      
      if isObserveAdded {
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        isObserveAdded = false
      }
      
      player?.pause()
      
      NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
      NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
      NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
      NotificationCenter.default.removeObserver(self, name: .AVPlayerUrlChanged, object: nil)
      NotificationCenter.default.removeObserver(self, name: .AVPlayerRateDidChange, object: nil)
      
      player = nil
      parentController = nil
      playerView = nil
      playerViewController = nil
      fullScreenController = nil
      overlay = nil
      fullScreenButton = nil
      thumbnailsUIImageFrames.removeAll()
      NotificationCenter.default.removeObserver(self)
    }
    
    func addNotificationObservers() {
      NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player)
      NotificationCenter.default.addObserver(self, selector: #selector(Coordinator.orientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
      NotificationCenter.default.addObserver(forName: .AVPlayerUrlChanged, object: nil, queue: .main, using: onChangePlaybackQuality)
      NotificationCenter.default.addObserver(forName: .AVPlayerRateDidChange, object: nil, queue: .main, using: onChangePlaybackRate)
    }
    
    @objc func handleAppDidEnterBackground() {
        if let player = player {
          oldTimeControlStatusOnBackground = player.timeControlStatus
        }
    }

    @objc func handleAppWillEnterForeground() {
      if let player = player {
        if oldTimeControlStatusOnBackground == .playing {
          DispatchQueue.main.async { [self] in
            player.play()
            player.rate = rate
          }
        }
      }
    }
    
    @objc func toggleFullScreen() {
      didHideOverlay()
      if isFullScreen {
        dismissFullScreen()
      } else {
        presentFullScreen()
      }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
        UIView.animate(withDuration: 0.35, animations: {
          self.didShowOverlay()
        })
      })
      
      if autoOrientationOnFullscreen {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute:  {
          if #available(iOS 16.0, *) {
            guard let windowSceen = self.parentController?.view.window?.windowScene else { return }
            if windowSceen.interfaceOrientation == .portrait && self.isFullScreen {
              windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            } else {
              windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
          } else {
            if UIDevice.current.orientation == .portrait && self.isFullScreen {
              let orientation = UIInterfaceOrientation.landscapeRight.rawValue
              UIDevice.current.setValue(orientation, forKey: "orientation")
            } else {
              let orientation = UIInterfaceOrientation.portrait.rawValue
              UIDevice.current.setValue(orientation, forKey: "orientation")
            }
          }
        })
      }
    }
    
    @objc func presentFullScreen() {
      guard let parentController = parentController?.view?.window?.rootViewController else { return }
      
      originalFrame = playerView.frame
      
      if parentController.presentedViewController != nil {
        return
      }
      
      let fullScreenController = UIViewController()
      self.fullScreenController = fullScreenController
      fullScreenController.view.backgroundColor = .black
      
      playerViewController.willMove(toParent: nil)
      playerView.removeFromSuperview()
      playerViewController.removeFromParent()
      
      fullScreenController.view.addSubview(playerView)
      addToSubviewAndBringToFront(view: overlay, superview: fullScreenController.view)
      fullScreenController.modalPresentationStyle = .overFullScreen
      
      parentController.present(fullScreenController, animated: false) {
        self.isFullScreen = true
        self.fullScreenButton?.isFullScreen = true
        self.playerView.center.x = fullScreenController.view.center.x
        
        if (UIDevice.current.orientation.isLandscape && self.autoEnterFullscreenOnLandscape) || self.autoOrientationOnFullscreen {
          self.playerView.frame = fullScreenController.view.bounds
        } else {
          UIView.animate(withDuration: 0.35, animations: {
            self.playerView.center.y = fullScreenController.view.center.y
          }, completion: { finished in
            if (finished) {
              self.playerView.frame = fullScreenController.view.bounds
              self.playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
          })
        }
      }
    }
    
    @objc func dismissFullScreen() {
      guard let parentController = parentController else { return }
      guard let fullScreenController = self.fullScreenController else { return }
      
      UIView.animate(withDuration: 0.35, animations: {
        self.playerView.center.y = parentController.view.center.y
      }, completion: { finished in
        
        if (finished) {
          fullScreenController.dismiss(animated: false) {
            self.fullScreenButton?.isFullScreen = false
            self.isFullScreen = false
            self.parentController?.view.addSubview(self.playerView)
            
            
            self.playerView.frame = parentController.view.frame
            self.playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            self.parentController?.addChild(self.playerViewController)
            self.playerViewController.didMove(toParent: parentController)
            self.addToSubviewAndBringToFront(view: self.overlay, superview: self.playerViewController!.view)
          }
        }
      }
      )
    }
    
    @objc func orientationDidChange(_ notification: Notification) {
      let device = notification.object as! UIDevice
      if device.orientation.isLandscape, self.autoEnterFullscreenOnLandscape, !self.isFullScreen {
        presentFullScreen()
      }
    }
    
    @objc func handleTapOverlayWithGesture(_ sender: UITapGestureRecognizer) {
      toggleOverlay()
    }
    
    func togglePlayback() {
      DispatchQueue.main.async { [self] in
        if player.timeControlStatus == .playing {
          player.pause()
        } else {
          player.play()
          player.rate = rate
          self.scheduleHideControls()
        }
      }
    }
    
    func configureAudioSession() {
        do {
          try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
          try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Erro ao configurar o AVAudioSession: \(error)")
        }
    }
    
    func generatingThumbnailsFrames(_ url: String) {
      Task.detached { [self] in
        let asset = AVAsset(url: URL(string: url)!)
        
        do {
          let totalDuration = asset.duration.seconds
          var framesTimes: [NSValue] = []
          
          // Generate thumbnails frames
          let generator = AVAssetImageGenerator(asset: asset)
          generator.appliesPreferredTrackTransform = true
          generator.maximumSize = .init(width: 250, height: 150)
          
          //  TODO:
          for progress in stride(from: 0, to: totalDuration / Double(1 * 100), by: 0.01) {
            let time = CMTime(seconds: totalDuration * Double(progress), preferredTimescale: 600)
            framesTimes.append(time as NSValue)
          }
          let localFrames = framesTimes
          
          generator.generateCGImagesAsynchronously(forTimes: localFrames) { requestedTime, image, _, _, error in
            guard let cgImage = image, error == nil else {
              return
            }
            
            DispatchQueue.main.async { [self] in
              let uiImage = UIImage(cgImage: cgImage)
              thumbnailsUIImageFrames.append(uiImage)
              NotificationCenter.default.post(name: .AVPlayerThumbnails, object: thumbnailsUIImageFrames)
            }
          }
        }
      }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
      let player = object as? AVPlayer
      if keyPath == #keyPath(AVPlayer.timeControlStatus) {
        if let statusNumber = change?[.newKey] as? NSNumber, let status = AVPlayer.TimeControlStatus(rawValue: statusNumber.intValue) {
          switch status {
          case .playing:
            NotificationCenter.default.post(name: .AVPlayerTimeControlStatus, object: true)
          case .waitingToPlayAtSpecifiedRate:
            NotificationCenter.default.post(name: .AVPlayerTimeControlStatus, object: false)
          case .paused:
            NotificationCenter.default.post(name: .AVPlayerTimeControlStatus, object: false)
          default:
            break
          }
        }
      }
      
      if keyPath == #keyPath(AVPlayerItem.status) {
        if let statusNumber = change?[.newKey] as? NSNumber,
           let status = AVPlayerItem.Status(rawValue: statusNumber.intValue) {
          switch status {
          case .readyToPlay:
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
              self.loading.isHidden = true
              NotificationCenter.default.post(name: .AVPlayerInitialLoading, object: false)
            })
          case .failed:
            let nsError = NSError(
              domain: urlOfCurrentPlayerItem(to: player)?.absoluteString ?? "Unknown",
              code: -1,
              userInfo: [
                NSLocalizedDescriptionKey: "An unknown error occurred while playing.",
                NSLocalizedFailureReasonErrorKey: "Failed to play the video.",
                NSLocalizedRecoverySuggestionErrorKey: "Please check the video source or try again later."
              ]
            )
            NotificationCenter.default.post(name: .AVPlayerErrors, object: nsError)
          case .unknown:
            let nsError = NSError(
              domain: urlOfCurrentPlayerItem(to: player)?.absoluteString ?? "Unknown",
              code: -1,
              userInfo: [
                NSLocalizedDescriptionKey: "Error occurred with the URL. Received an unknown status code.",
                NSLocalizedFailureReasonErrorKey: "The status of the player is unknown.",
                NSLocalizedRecoverySuggestionErrorKey: "Please check the URL and try again."
              ]
            )
            NotificationCenter.default.post(name: .AVPlayerErrors, object: nsError)
          @unknown default:
            let nsError = NSError(
              domain: "UnknownStatus",
              code: -1,
              userInfo: [
                NSLocalizedDescriptionKey: "An unknown player status occurred.",
                NSLocalizedFailureReasonErrorKey: "Unhandled AVPlayerItem status detected.",
                NSLocalizedRecoverySuggestionErrorKey: "Please update the app to handle this status."
              ]
            )
            NotificationCenter.default.post(name: .AVPlayerErrors, object: nsError)
          }
          
        }
      }
    }
    
    func addToSubviewAndBringToFront(view: UIView, superview: UIView) {
      superview.addSubview(view)
      superview.bringSubviewToFront(view)
      
      view.translatesAutoresizingMaskIntoConstraints = false
      view.backgroundColor = .black.withAlphaComponent(0.4)
      
      NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: superview.topAnchor),
        view.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
        view.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: superview.trailingAnchor)
      ])
    }
    
    func toggleOverlay() {
      UIView.animate(withDuration: 0.35) { [self] in
        if (controlsVisible) {
          didHideOverlay()
        } else {
          didShowOverlay()
        }
      }
    }
    
    func didHideOverlay() {
      overlay.alpha = 0.004
      controlsVisible = false
    }
    
    func didShowOverlay() {
      overlay.alpha = 1
      controlsVisible = true
    }
    
    func onBackwardTime(_ timeToChange: Int) {
      guard let currentItem = player.currentItem else { return }
      
      let currentTime = CMTimeGetSeconds(player.currentTime())
      let newTime = max(currentTime - Double(timeToChange), 0)
      player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                  toleranceBefore: .zero,
                  toleranceAfter: .zero,
                  completionHandler: { _ in })
    }
    
    func onForwardTime(_ timeToChange: Int) {
        guard let currentItem = player.currentItem else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        
        let newTime = max(currentTime + Double(timeToChange), 0)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                    toleranceBefore: .zero,
                    toleranceAfter: .zero,
                    completionHandler: { _ in })
    }
    
    func scheduleHideControls() {
      DispatchQueue.main.async { [self] in
        if let timeoutWorkItem {
          timeoutWorkItem.cancel()
        }
        
        if (player.timeControlStatus == .playing) {
          self.timeoutWorkItem = .init(block: {
            UIView.animate(withDuration: 0.35) { [self] in
              didHideOverlay()
            }
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
    
    func onChangePlaybackQuality(_ notification: Notification) {
      let url = notification.object as! String
      
      guard let player = player else { return }
      
      let newUrl = URL(string: url)
      
      if (newUrl == urlOfCurrentPlayerItem(to: player)) {
        return
      }
      
      let currentTime = player.currentItem?.currentTime() ?? CMTime.zero
      let asset = AVURLAsset(url: newUrl!)
      let newPlayerItem = AVPlayerItem(asset: asset)
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [self] in
        player.replaceCurrentItem(with: newPlayerItem)
        player.seek(to: currentTime)
        
        newPlayerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        var playerItemStatusObservation: NSKeyValueObservation?
        playerItemStatusObservation = newPlayerItem.observe(\.status, options: [.new]) { (item, _) in
          guard item.status == .readyToPlay else {
            NotificationCenter.default.post(name: .AVPlayerErrors, object: extractPlayerItemError(item))
            return
          }
          playerItemStatusObservation?.invalidate()
        }
      })
    }
    
    func onChangePlaybackRate(_ notification: Notification) {
      let newRate = notification.object as! Float;
      
      DispatchQueue.main.async(execute: { [weak self] in
        self?.rate = newRate
        if (self?.player?.timeControlStatus == .playing) {
          self?.player?.rate = newRate
        }
      })
      
    }
    
    func urlOfCurrentPlayerItem(to player : AVPlayer?) -> URL? {
      return ((player?.currentItem?.asset) as? AVURLAsset)?.url
    }
    
    @objc func playerDidFinishPlaying(_ notification: Notification) {
      player.pause()
    }
    
    func resetPlaybackStatus() {
      self.player?.seek(to: .zero, completionHandler: { completed in
            if (completed) {
              self.player?.play()
              self.scheduleHideControls()
              self.playPauseButton?.isHidden = false
            }
        })
    }
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

}


class CustomUIViewController: UIViewController {
  var onDisappear: (() -> Void)?
  
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    onDisappear?()
  }
}
