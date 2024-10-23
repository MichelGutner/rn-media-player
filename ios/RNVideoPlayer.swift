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
  
  weak var player: AVPlayer? = nil
  private var isInitialized = false
  private var isFullScreen = false
  private var UIControlsProps: HashableUIControls? = .none
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
      setupPlayer()
    }
  }
  
  @objc var rate: Float = 0.0 {
    didSet {
            NotificationCenter.default.post(name: .AVPlayerRateDidChange, object: rate)
    }
  }
  
  @objc var paused: Bool = false {
    didSet {
      // ADD Notification
    }
  }
  
  @objc var changeQualityUrl: String = "" {
    didSet {
      let url = changeQualityUrl
      if (url.isEmpty) { return }
      NotificationCenter.default.post(name: .AVPlayerUrlChanged, object: url)
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    NotificationCenter.default.addObserver(forName: .AVPlayerErrors, object: nil, queue: .main, using: { notification in
      let error = notification.object as? NSError
      self.onError?([
        "domain": error?.domain,
        "code": error?.code,
        "userInfo": [
          "description": error?.userInfo[NSLocalizedDescriptionKey],
          "failureReason": error?.userInfo[NSLocalizedFailureReasonErrorKey],
          "fixSuggestion": error?.userInfo[NSLocalizedRecoverySuggestionErrorKey]
        ]
      ])
    })
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc var resizeMode: NSString = "contain"
  
  private func setupPlayer() {
    DispatchQueue.main.async { [self] in
      releaseResources()
      if let url = source?["url"] as? String, let videoURL = URL(string: url) {
        
        self.player = AVPlayer(url: videoURL)
        self.initializePlayer()
      }
    }
  }
  
  private func initializePlayer() {
    let thumbnailsProps = source?["thumbnails"] as? NSDictionary
    let startTime = source?["startTime"] as? Double ?? 0.0
    player?.seek(to: CMTime(seconds: startTime, preferredTimescale: 1))
    
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
      
      UIControlsProps = HashableUIControls(
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
    
    let viewController = UIHostingController(
      rootView: ViewController(
        player: player,
        autoPlay: autoPlay,
        menus: menus,
        bridgeControls: PlayerControls (
          togglePlayback: {_ in },
          optionSelected: { [weak self] name, value in
            self?.onMenuItemSelected?(["name": name, "value": value])
          }
        ),
        autoOrientationOnFullscreen: autoOrientationOnFullscreen,
        autoEnterFullscreenOnLandscape: autoEnterFullscreenOnLandscape,
        thumbnails: thumbnailsProps,
        tapToSeek: tapToSeek,
        UIControls: UIControlsProps,
        videoGravity: videoGravity
      )
    )
    
    uiView = viewController.view
    uiView.clipsToBounds = true
    addSubview(uiView)
    setNeedsLayout()
  }
  
  override func layoutSubviews() {
    uiView.frame = bounds
    super.layoutSubviews()
  }
  
  override func removeFromSuperview() {
    super.removeFromSuperview()
    uiView.removeFromSuperview()
    releaseResources()
  }
  
  private func releaseResources() {
    player?.replaceCurrentItem(with: nil)
    player?.pause()
    player = nil
    NotificationCenter.default.removeObserver(self, name: .AVPlayerErrors, object: nil)
    NotificationCenter.default.removeObserver(self, name: .AVPlayerSource, object: nil)
    NotificationCenter.default.removeObserver(self, name: .AVPlayerRateDidChange, object: nil)
    NotificationCenter.default.removeObserver(self, name: .AVPlayerUrlChanged, object: nil)
    setNeedsLayout()
  }
}


protocol PlayerControlsProtocol {
    func togglePlayback()
}

struct PlayerControls {
  var togglePlayback: (_ status: Bool) -> Void
  var optionSelected: (_ label: String, _ value: Any) -> Void
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
}
