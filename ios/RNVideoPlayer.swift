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
  @ObservedObject private var mediaSession = MediaSessionManager()
  private var videoPlayerView: VideoPlayerViewController? = .none
  private var player: AVPlayer? = nil
  
  @State private var thumbnailsUIImageFrames: [UIImage] = []
  
  private var session = AVAudioSession.sharedInstance()
  private var mainView = UIView()

  private var isInitialized = false
  private var UIControlsProps: Styles? = .none
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
  
  @objc var controlsStyles: NSDictionary? = [:]
  @objc var tapToSeek: NSDictionary? = [:]
  
  @objc var source: NSDictionary? = [:] {
    didSet {
      setupPlayer()
    }
  }
  
  @objc var rate: Float = 0.0 {
    didSet {
      adjustPlaybackRate(to: rate)
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
      updatePlayerWithNewURL(url)
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    NotificationCenter.default.addObserver(forName: .MenuSelectedOption, object: nil, queue: .main, using: { notification in
      let tupleValues = notification.object as? (String, Any)
      let name = tupleValues?.0
      let value = tupleValues?.1
      self.onMenuItemSelected?(["name": name ?? "", "value": value as Any])
    })
    
    NotificationCenter.default.addObserver(forName: .AVPlayerErrors, object: nil, queue: .main, using: { notification in
      let error = notification.object as? NSError
      self.onError?([
        "domain": error?.domain ?? "",
        "code": error?.code ??  0,
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
    videoPlayerView?.releaseResources()
    
    guard let urlString = source?["url"] as? String,
          let videoURL = URL(string: urlString) else {
      print("URL not found.")
      return
    }
    let startTime = source?["startTime"] as? Double ?? 0
    
    DispatchQueue.main.async { [self] in
      self.player = AVPlayer(url: videoURL)
      self.player?.seek(to: CMTime(seconds: startTime, preferredTimescale: 1))
      
      if self.autoPlay == true {
          self.player?.play()
      }
      
      if let metadata = source?["metadata"] as? NSDictionary {
        player?.currentItem!.externalMetadata = createMetadata(for: metadata)
      }
      
      if let player {
        videoPlayerView = VideoPlayerViewController(player: player, mediaSession: mediaSession, menus: menus)
        if let wrapper = videoPlayerView?.view {
          addSubview(wrapper)
        }
      }
      
      mediaSession.makeNowPlayingInfo()
      mediaSession.setupRemoteCommandCenter()
      mediaSession.thumbnailsDictionary = source?["thumbnails"] as? NSDictionary
    }
  }
  
  private func createMetadata(for source: NSDictionary?) -> [AVMetadataItem] {
    var metadataItems: [AVMetadataItem] = []
    
    if let source {
      for (key, value) in source {
        guard let keyString = key as? String,
              let valueString = value as? String else {
            continue
        }
        
        guard let identifier = mapKeyToMetadataIdentifier(keyString) else { continue }
        
        let metadataItem = AVMutableMetadataItem()
        metadataItem.identifier = identifier
        metadataItem.value = valueString as NSString
        metadataItem.locale = Locale.current
        
        metadataItems.append(metadataItem)
      }
    }
    
    return metadataItems
  }
  
  private func mapKeyToMetadataIdentifier(_ key: String) -> AVMetadataIdentifier? {
      switch key {
      case "title":
          return .commonIdentifierTitle
      case "artist":
          return .commonIdentifierArtist
      case "albumName":
          return .commonIdentifierAlbumName
      default:
          return nil
      }
  }
  
//  private func initializePlayer() {
//    let thumbnailsProps = source?["thumbnails"] as? NSDictionary
//    let startTime = source?["startTime"] as? Double ?? 0.0
//    player?.seek(to: CMTime(seconds: startTime, preferredTimescale: 1))
//    
//    if let controllersProps = controlsStyles {
//      let playbackProps = PlaybackControlsStyle(dictionary: controllersProps["playback"] as? NSDictionary)
//      let seekSliderProps = SeekSliderStyle(dictionary: controllersProps["seekSlider"] as? NSDictionary)
//      let timeCodesProps = TimeCodesStyle(dictionary: controllersProps["timeCodes"] as? NSDictionary)
//      let menusUiConfig = MenusStyle(dictionary: controllersProps["menus"] as? NSDictionary)
//      let fullScreenProps = FullScreenButtonStyle(dictionary: controllersProps["fullScreen"] as? NSDictionary)
//      let downloadProps = DownloadControlHashableProps(dictionary: controllersProps["download"] as? NSDictionary)
//      let toastProps = ToastStyle(dictionary: controllersProps["toast"] as? NSDictionary)
//      let headerProps = HeaderStyle(dictionary: controllersProps["header"] as? NSDictionary)
//      let loadingProps = LoadingStyle(dictionary: controllersProps["loading"] as? NSDictionary)
//      
//      UIControlsProps = Styles(
//        playbackControl: playbackProps,
//        seekSliderControl: seekSliderProps,
//        timeCodesControl: timeCodesProps,
//        menusControl: menusUiConfig,
//        fullScreenControl: fullScreenProps,
//        downloadControl: downloadProps,
//        toastControl: toastProps,
//        headerControl: headerProps,
//        loadingControl: loadingProps
//      )
//    }
//    
//    let mode = Resize(rawValue: resizeMode as String)
//    let videoGravity = self.videoGravity(mode!)
//    
//    if let autoEnterFullscreen = screenBehavior["autoEnterFullscreenOnLandscape"] as? Bool {
//      self.autoEnterFullscreenOnLandscape = autoEnterFullscreen
//    }
//    if let autoOrientationOnFullscreen = screenBehavior["autoOrientationOnFullscreen"] as? Bool {
//      self.autoOrientationOnFullscreen = autoOrientationOnFullscreen
//    }
//    
//    let viewController = UIHostingController(
//      rootView: ViewController(
//        player: player,
//        autoPlay: autoPlay,
//        menus: menus,
//        bridgeControls: PlayerControls (
//          togglePlayback: {_ in },
//          optionSelected: { [weak self] name, value in
//            self?.onMenuItemSelected?(["name": name, "value": value])
//          }
//        ),
//        autoOrientationOnFullscreen: autoOrientationOnFullscreen,
//        autoEnterFullscreenOnLandscape: autoEnterFullscreenOnLandscape,
//        thumbnails: thumbnailsProps,
//        tapToSeek: tapToSeek,
//        UIControls: UIControlsProps,
//        videoGravity: videoGravity
//      )
//    )
//    
//    mainView = viewController.view
//    mainView.clipsToBounds = true
//    addSubview(mainView)
//    setNeedsLayout()
//  }
  
  override func layoutSubviews() {
    videoPlayerView?.view.frame = bounds
    super.layoutSubviews()
  }
  
  override func removeFromSuperview() {
    videoPlayerView?.releaseResources()
  }
  
  @objc private func updatePlayerWithNewURL(_ url: String) {
    guard let player else { return }
    
    let newUrl = URL(string: url)
    
    if (newUrl == mediaSession.urlOfCurrentPlayerItem()) {
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
  
  @objc private func adjustPlaybackRate(to rate: Float) {
    mediaSession.newRate = rate
    DispatchQueue.main.async(execute: { [self] in
      if (self.player?.timeControlStatus == .playing) {
        self.player?.rate = rate
      }
    })
  }
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
