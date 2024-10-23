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
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
        NotificationCenter.default.post(name: .AVPlayerSource, object: self.source)
      })
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
  
  private func setup() {
    uiView.removeFromSuperview()
    let thumbnailsProps = source?["thumbnails"] as? NSDictionary
    
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
        source: source,
        autoPlay: autoPlay,
        menus: menus,
        bridgeControls: PlayerControls (
          togglePlayback: {_ in },
          optionSelected: { name, value in
            self.onMenuItemSelected?(["name": name, "value": value])
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
  }
  
  override func layoutSubviews() {
    uiView.frame = bounds
    
    if (!isInitialized) {
      print("did enter")
        self.setup()
        self.superview?.addSubview(self.uiView)
      isInitialized = true
    }
    
    super.layoutSubviews()
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
