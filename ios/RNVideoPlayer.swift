import AVKit
import SwiftUI
import UIKit
import React
import AVFoundation

@available(iOS 14.0, *)
@objc(RNVideoPlayer)
class RNVideoPlayer: RCTViewManager {
  @objc override func view() -> (RNVideoPlayerView) {
    return RNVideoPlayerView()
  }
  
  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}

@available(iOS 14.0, *)
class RNVideoPlayerView : UIView {
  private var session = AVAudioSession.sharedInstance()
  private var uiView = UIView()
  
  private var player: AVPlayer?
  private var isInitialized = false
  private var isFullScreen = false
  private var UIControlsProps: HashableControllers? = .none
  private var autoEnterFullscreenOnLandscape = false
  private var autoOrientationOnFullscreen = false
  
  @objc var autoPlay: Bool = false
  @objc var menus: NSDictionary? = [:]
  @objc var onMenuItemSelected: RCTBubblingEventBlock?
  
  @objc var onVideoProgress: RCTBubblingEventBlock?
  @objc var onLoaded: RCTBubblingEventBlock?
  @objc var onCompleted: RCTBubblingEventBlock?
  @objc var onFullScreen: RCTDirectEventBlock?
  @objc var onError: RCTDirectEventBlock?
  @objc var onBuffer: RCTDirectEventBlock?
  @objc var onBufferCompleted: RCTDirectEventBlock?
  @objc var onGoBackTapped: RCTDirectEventBlock?
  @objc var onVideoDownloaded: RCTDirectEventBlock?
  @objc var onDownloadVideo: RCTDirectEventBlock?
  @objc var onPlayPause: RCTDirectEventBlock?
  
  @objc var thumbnailFramesSeconds: Float = 1.0
  @objc var screenBehavior: NSDictionary = [:]
  
  @objc var controlsProps: NSDictionary? = [:]
  @objc var tapToSeek: NSDictionary? = [:]
  
  @objc var source: NSDictionary? = [:] {
    didSet {
      initializePlayer(source)
    }
  }
  
  @objc var rate: Float = 0.0 {
    didSet {
      NotificationCenter.default.post(name: .AVPlayerRateDidChange, object: nil, userInfo: ["rate": rate])
    }
  }
  
  @objc var paused: Bool = false {
    didSet {
      self.onPaused(paused)
    }
  }
  
  @objc var changeQualityUrl: String = "" {
    didSet {
      let url = changeQualityUrl
      if (url.isEmpty) { return }
      self.onChangePlaybackQuality(URL(string: url)!)
    }
  }
  
  @objc var resizeMode: NSString = "contain"
  
  private func initializePlayer(_ source: NSDictionary?) {
    let url = source?["url"] as? String
    let startTime = source?["startTime"] as? Float
    releasePlayerResources()
    
    player = AVPlayer(url: URL(string: url!)!)
    
    guard let player = player else { return }
    player.currentItem?.seek(to: CMTime(seconds: Double(startTime ?? 0), preferredTimescale: 2), completionHandler: nil)
    
    player.actionAtItemEnd = .none
    player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
    player.addObserver(self, forKeyPath: "rate", options: [.new, .old], context: nil)
    player.addObserver(self, forKeyPath: "timeControlStatus", options: [.new, .initial], context: nil)
    
    player.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
    player.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
    player.currentItem?.addObserver(self, forKeyPath: "playbackBufferFull", options: .new, context: nil)
    self.setNeedsLayout()
  }
  
  private func setup() {
    uiView.removeFromSuperview()
    let thumbnailsProps = source?["thumbnails"] as? NSDictionary
    
    guard let avPlayer = player else { return }
    
    if let controllersProps = controlsProps {
      let playbackProps = PlaybackControlHashableProps(dictionary: controllersProps["playback"] as? NSDictionary)
      let seekSliderProps = SeekSliderControlHashableProps(dictionary: controllersProps["seekSlider"] as? NSDictionary)
      let timeCodesProps = TimeCodesHashableProps(dictionary: controllersProps["timeCodes"] as? NSDictionary)
      let menusUiConfig = MenusUIConfig(dictionary: controllersProps["menus"] as? NSDictionary)
      let fullScreenProps = FullScreenControlHashableProps(dictionary: controllersProps["fullScreen"] as? NSDictionary)
      let downloadProps = DownloadControlHashableProps(dictionary: controllersProps["download"] as? NSDictionary)
      let toastProps = ToastHashableProps(dictionary: controllersProps["toast"] as? NSDictionary)
      let headerProps = HeaderControlHashableProps(dictionary: controllersProps["header"] as? NSDictionary)
      let loadingProps = LoadingHashableProps(dictionary: controllersProps["loading"] as? NSDictionary)
      
      UIControlsProps = HashableControllers(
        playbackControl: playbackProps,
        seekSliderControl: seekSliderProps,
        timeCodesControl: timeCodesProps,
        menusControl: menusUiConfig,
        fullScreenControl: fullScreenProps,
        downloadControl: downloadProps,
        toastControl: toastProps,
        headerControl: headerProps,
        loadingControl: loadingProps
      )
    }
    
    let mode = Resize(rawValue: resizeMode as String)
    let videoGravity = self.videoGravity(mode!)

    if let autoEnterFullscreen = screenBehavior["autoEnterFullscreenOnLandscape"] as? Bool {
      self.autoEnterFullscreenOnLandscape = autoEnterFullscreen
    }
    if let autoOrientationOnFullscreen = screenBehavior["autoOrientationOnFullscreen"] as? Bool {
      self.autoOrientationOnFullscreen = autoOrientationOnFullscreen
    }
    
        let uiHostingView = UIHostingController(rootView: VideoPlayerView(
          player: avPlayer,
          autoPlay: .constant(autoPlay),
          options: menus,
          controls: PlayerControls(
            togglePlayback: {
              if (avPlayer.timeControlStatus == .playing) {
                avPlayer.pause()
                self.onPlayPause?(["isPlaying": false])
              } else {
                avPlayer.play()
                self.onPlayPause?(["isPlaying": true])
              }
            },
            optionSelected: { name, value in
              self.onMenuItemSelected?(["name": name, "value": value])
            },
            toggleFullScreen: { [self] in
              toggleFullScreen(!isFullScreen)
            }
          ),
          thumbNailsProps: thumbnailsProps,
          enterInFullScreenWhenDeviceRotated: autoEnterFullscreenOnLandscape,
          videoGravity: videoGravity,
          UIControlsProps: .constant(UIControlsProps),
          tapToSeek: tapToSeek
        ).onDisappear { [self] in
          releasePlayerResources()
        })
    
    uiView = uiHostingView.view
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    activateSession()
    setupBackgroundObservers()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    if (!isInitialized) {
      isInitialized = true
      setup()
    }
    
    let currentOrientation = UIDevice.current.orientation
    
    if autoEnterFullscreenOnLandscape, currentOrientation.isLandscape {
      DispatchQueue.main.async { [self] in
        toggleFullScreen(true)
      }
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now()) { [self] in
      uiView.backgroundColor = .black
      uiView.clipsToBounds = true
      
      
      if (isFullScreen) {
        uiView.frame = UIScreen.main.bounds
        return
      }
      
      if frame.height > UIScreen.main.bounds.height {
        withAnimation(.easeInOut(duration: 0.35)) {
          uiView.frame = UIScreen.main.bounds
        }
        
      } else {
        withAnimation(.easeInOut(duration: 0.35)) {
          uiView.frame = bounds
        }
      }
      superview?.addSubview(uiView)
    }
    
    super.layoutSubviews()
  }
  
  @objc private func orientationDidChange() {
    let currentOrientation = UIDevice.current.orientation
    
    
    if autoEnterFullscreenOnLandscape, currentOrientation.isLandscape {
      DispatchQueue.main.asyncAfter(deadline: .now()) { [self] in
        toggleFullScreen(true)
      }
    }
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if let player = object as? AVPlayer {
      NotificationCenter.default.post(name: .AVPlayerTimeControlStatus, object: player.timeControlStatus)
    }
    
    if keyPath == "rate" {
      NotificationCenter.default.post(name: .AVPlayerRateDidChange, object: player)
    }
    if let playerItem = object as? AVPlayerItem {
      NotificationCenter.default.post(name: .PlayerItem, object: playerItem)
    }
  }

  private func activateSession() {
    do {
      try session.setCategory(
        .playback,
        mode: .default,
        options: [.mixWithOthers]
      )
    } catch _ {}
    
    do {
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch _ {}
    
    do {
      try session.overrideOutputAudioPort(.speaker)
    } catch _ {}
  }
  
  @objc func toggleFullScreen(_ fullScreen: Bool) {
    if fullScreen {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: { [self] in
        uiView.removeFromSuperview()
        uiView.frame = UIScreen.main.bounds
        superview?.addSubview(uiView)
      })
    } else {
      uiView.removeFromSuperview()
      
      if frame.height > UIScreen.main.bounds.height {
        withAnimation(.easeInOut(duration: 0.35)) {
          uiView.frame = UIScreen.main.bounds
        }
      } else {
        withAnimation(.easeInOut(duration: 0.35)) {
          uiView.frame = frame
        }
      }
      superview?.addSubview(uiView)
    }
    
    if autoOrientationOnFullscreen {
      DispatchQueue.main.async {
        if #available(iOS 16.0, *) {
          guard let windowSceen = self.window?.windowScene else { return }
          if windowSceen.interfaceOrientation == .portrait {
            windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
          } else {
            windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
          }
        } else {
          if UIDevice.current.orientation == .portrait {
            let orientation = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(orientation, forKey: "orientation")
          } else {
            let orientation = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(orientation, forKey: "orientation")
          }
        }
      }
    }
    
    isFullScreen = fullScreen
  }

  
  @objc private func onPaused(_ paused: Bool) {
    if paused {
      player?.pause()
    } else {
      player?.play()
    }
  }
  
  private func setupBackgroundObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleWillResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
  }
  
  @objc private func handleDidEnterBackground() {
    player?.pause()
  }
  
  @objc private func handleWillEnterForeground() {
    player?.play()
  }
  
  @objc private func handleWillResignActiveNotification() {
    print("lose")
  }
}


protocol PlayerControlsProtocol {
    func togglePlayback()
}

struct PlayerControls {
    var togglePlayback: () -> Void
    var optionSelected: (_ label: String, _ value: Any) -> Void
    var toggleFullScreen: () -> Void
}



struct Controls {
    var menuItemSelected: (_ label: String, _ value: Any) -> Void
}

@available(iOS 14.0, *)
extension RNVideoPlayerView {
  func videoGravity(_ videoResize: Resize) -> AVLayerVideoGravity  {
    switch (videoResize) {
    case .stretch:
      return .resize
    case .cover:
      return .resizeAspectFill
    case .contain:
      return .resizeAspect
    }
  }
  
  private func onChangePlaybackQuality(_ url: URL) {
    guard let player = player else { return }
    
    if (url == urlOfCurrentPlayerItem(player: player)) {
      return
    }
    let currentTime = player.currentItem?.currentTime() ?? CMTime.zero
    let asset = AVURLAsset(url: url)
    let newPlayerItem = AVPlayerItem(asset: asset)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [self] in
      player.replaceCurrentItem(with: newPlayerItem)
      player.seek(to: currentTime)
      
      newPlayerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
      var playerItemStatusObservation: NSKeyValueObservation?
      playerItemStatusObservation = newPlayerItem.observe(\.status, options: [.new]) { [weak self] (item, _) in
        guard item.status == .readyToPlay else {
          self?.onError?(extractPlayerErrors(item))
          return
        }
        playerItemStatusObservation?.invalidate()
      }
    })
  }
  
  private func urlOfCurrentPlayerItem(player : AVPlayer) -> URL? {
    return ((player.currentItem?.asset) as? AVURLAsset)?.url
  }
  
  private func releasePlayerResources() {
      player?.removeObserver(self, forKeyPath: "status")
      player?.removeObserver(self, forKeyPath: "rate")
      player?.removeObserver(self, forKeyPath: "timeControlStatus")
      
      if let currentItem = player?.currentItem {
          currentItem.removeObserver(self, forKeyPath: "playbackBufferEmpty")
          currentItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
          currentItem.removeObserver(self, forKeyPath: "playbackBufferFull")
      }
      
      player?.pause()
      player = nil
      
      NotificationCenter.default.removeObserver(self)
      
      uiView.removeFromSuperview()
      print("Video player removed with successfully.")
  }
}
