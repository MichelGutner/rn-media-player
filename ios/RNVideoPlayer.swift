import AVKit
import SwiftUI
import UIKit
import React
import AVFoundation
import Combine

@available(iOS 14.0, *)
@objc(RNVideoPlayer)
class RNVideoPlayer: RCTViewManager {
  @objc override func view() -> (RNVideoPlayerViewX) {
    return RNVideoPlayerViewX()
  }
  
  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}


class MediaPlayerEventDispatcher : UIView {
  @objc var onMenuItemSelected: RCTBubblingEventBlock?
  @objc var onMediaPlayPause: RCTDirectEventBlock?
  @objc var onMediaError: RCTDirectEventBlock?
  @objc var onMediaBuffering: RCTBubblingEventBlock?
  @objc var onMediaSeekBar: RCTDirectEventBlock?
  @objc var onMediaReady: RCTBubblingEventBlock?
  @objc var onMediaCompleted: RCTBubblingEventBlock?
  @objc var onFullScreenStateChanged: RCTDirectEventBlock?
  @objc var onMediaBufferCompleted: RCTDirectEventBlock?
  @objc var onMediaPinchZoom: RCTDirectEventBlock?
  
  @objc var onMediaRouter: RCTDirectEventBlock?
  
  public enum Dispatcher {
    case onMenuItemSelected
    case onMediaPlayPause
    case onMediaError
    case onMediaBuffering
    case onMediaSeekBar
    case onMediaReady
    case onMediaCompleted
    case onFullScreenStateChanged
    case onMediaBufferCompleted
    case onMediaPinchZoom
  }
  
  func sendEvent(_ dispatcher: Dispatcher, _ receivedValue: Any) {
    switch dispatcher {
    case .onMenuItemSelected:
      let values = receivedValue as! (String, Any)
      onMenuItemSelected?(["name": values.0, "value": values.1])
    case .onMediaPlayPause:
      onMediaPlayPause?(["isPlaying": receivedValue])
    case .onMediaError:
      let error = receivedValue as! NSError
      onMediaError?([
        "domain": error.domain,
        "code": error.code,
        "userInfo": [
          "description": error.userInfo[NSLocalizedDescriptionKey],
          "failureReason": error.userInfo[NSLocalizedFailureReasonErrorKey],
          "fixSuggestion": error.userInfo[NSLocalizedRecoverySuggestionErrorKey]
        ]
      ])
    case .onMediaBuffering:
      onMediaBuffering?(receivedValue as? [AnyHashable : Any])
    case .onMediaSeekBar:
      onMediaSeekBar?(receivedValue as? [AnyHashable : Any])
    case .onMediaReady:
      onMediaReady?(receivedValue as? [AnyHashable : Any])
    case .onMediaCompleted:
      onMediaCompleted?(receivedValue as? [AnyHashable : Any])
    case .onFullScreenStateChanged:
      onFullScreenStateChanged?(receivedValue as? [AnyHashable : Any])
    case .onMediaBufferCompleted:
      onMediaBufferCompleted?(receivedValue as? [AnyHashable : Any])
    case .onMediaPinchZoom:
      onMediaPinchZoom?(receivedValue as? [AnyHashable : Any])
    }
  }
}

@available(iOS 14.0, *)
class RNVideoPlayerViewX : MediaPlayerEventDispatcher {
  fileprivate var mediaSource = PlayerSource()
  fileprivate var playerLayerVC: RCTMediaPlayerLayerController?
  fileprivate var controlsVC: UIHostingController<MediaPlayerControlsView>?
  fileprivate var rootControlsView: MediaPlayerControlsView?
  fileprivate var videoThumbnailGenerator: VideoThumbnailGenerator?
  fileprivate var isFullscreen: Bool = false
  
  fileprivate var cancellables: Set<AnyCancellable> = []

  @objc var entersFullScreenWhenPlaybackBegins: Bool = false
  
  @objc var controlsStyles: NSDictionary? = [:]
  
  
  @objc var doubleTapToSeek: NSDictionary? = nil {
    didSet {
      if oldValue != doubleTapToSeek {
        RCTConfigManager.setDoubleTapToSeek(with: doubleTapToSeek)
      }
    }
  }
  
  @objc var rate: Float = 1.0 {
    didSet {
      if !rate.isNaN || oldValue != rate {
        mediaSource.setRate(to: rate)
      }
    }
  }
  
  @objc var replaceMediaUrl: String? = nil {
      didSet {
          guard let validUrl = replaceMediaUrl, !validUrl.isEmpty else { return }
          mediaSource.setPlayerWithNewURL(validUrl) { success, error in
              if success {
                  appConfig.log("[PlayerSource] Player updated successfully.")
              } else if let error = error {
                  self.sendEvent(.onMediaError, error)
              }
          }
      }
  }

  
  @objc var autoPlay: Bool = false
  
  @objc var source: NSDictionary? = [:] {
    didSet {
      mediaSource.setup(with: source) { [self] player in
        playerLayerVC = RCTMediaPlayerLayerController(player: player)
        setup()
      }
    }
  }
  
  @objc var menus: NSDictionary? = [:] {
    didSet {
      appConfig.playbackMenu = menus
    }
  }
  
  @objc var thumbnails: NSDictionary? = [:] {
    didSet {
      if thumbnails != nil {
        guard let thumbnails,
              let enabled = thumbnails["isEnabled"] as? Bool,
              enabled,
              let url = thumbnails["sourceUrl"] as? String
        else { return }
        videoThumbnailGenerator = VideoThumbnailGenerator(videoURL: url) { image, completed in
          ThumbnailManager.setImage(image)
          if completed {
            appConfig.log("[Thumbnails] all images generated successfully")
          }
        }
      }
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    addNotificationsObservers()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
      playerLayerVC?.view.frame = bounds
    super.layoutSubviews()
  }
  
  override func removeFromSuperview() {
    mediaSource.prepareToDeInit()
    playerLayerVC?.prepareToDeInit()
    videoThumbnailGenerator?.cancel()
    ThumbnailManager.clearImages()
  }
  
  private func setup() {
    appConfig.isLoggingEnabled.toggle()
    rootControlsView = MediaPlayerControlsView(mediaSource: mediaSource)
    rootControlsView?.delegate = self
    controlsVC = UIHostingController(rootView: rootControlsView!)
    
    mediaSource.delegate = self
    if let playerLayerVC {
      playerLayerVC.addContentOverlayController(with: controlsVC!)
      playerLayerVC.delegate = self
      addSubview(playerLayerVC.view)
    }

    appConfig.log("teessttss, autoply: \(autoPlay)")
    if autoPlay {
      mediaSource.setPlaybackState(to: .playing)
    }
  }
  
  private func addNotificationsObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(didEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }
  
  @objc fileprivate func didEnterForeground() {
    mediaSource.setPlaybackState(to: .playing)
  }
  
  @objc fileprivate func didEnterBackground() {
    mediaSource.setPlaybackState(to: .waiting)
  }
}


@available(iOS 14.0, *)
extension RNVideoPlayerViewX: RCTMediaPlayerLayerManagerProtocol {
  func playerLayerControlView(_ playerLayer: RCTMediaPlayerLayerController, isReadyForDisplay state: Bool, duration: Double) {
    sendEvent(.onMediaReady, ["loaded": state, "duration": duration])
    mediaSource.setIsReadyToPlay(state)
  }
  
  func playerLayerControlView(_ playerLayer: RCTMediaPlayerLayerController, didRequestControl action: RCTLayerManagerActionType, didChangeState state: Any?) {
    switch action {
    case .pinchToZoom:
      sendEvent(.onMediaPinchZoom, state!)
    case .fullscreen:
      sendEvent(.onFullScreenStateChanged, ["isFullscreen": state])
      DispatchQueue.main.async {
        SharedScreenState.setFullscreenState(to: state as? Bool ?? false)
      }
    }
  }
}

@available(iOS 14.0, *)
extension RNVideoPlayerViewX: PlayerSourceViewDelegate {
  func mediaPlayer(_ control: PlayerSource, currentTime: Double, duration: Double, bufferingProgress: CGFloat) {
    let timeInfo: [String: Any] = ["totalBuffered": bufferingProgress, "progress": currentTime]
    let bufferCompleted: [String: Any] = ["completed": bufferingProgress >= duration]
    sendEvent(.onMediaBuffering, timeInfo)
    sendEvent(.onMediaBufferCompleted, bufferCompleted)
  }
  
  func mediaPlayer(_ player: PlayerSource, didChangeReadyToDisplay isReadyToDisplay: Bool) {
    appConfig.log("[PlayerSourceDelegate] isReadyToDisplay -> \(isReadyToDisplay)")
    PlaybackManager.setIsReadyForDisplay(to: isReadyToDisplay)
    if entersFullScreenWhenPlaybackBegins {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
        self.playerLayerVC?.didPresentFullscreen()
      })
    }
    
    if autoPlay {
      mediaSource.setPlaybackState(to: .playing)
    }
  }
  
  func mediaPlayer(_ player: PlayerSource, loadFail error: (any Error)?) {
    sendEvent(.onMediaError, error as Any)
  }
  
  func mediaPlayer(_ player: PlayerSource, didChangePlaybackState state: PlaybackState) {
    let isFinished = state == .ended
    if isFinished {
      sendEvent(.onMediaCompleted, ["completed": true])
    }
    PlaybackManager.updateIsPlaying(to: state == .playing)
  }
  
  func mediaPlayer(_ player: PlayerSource, playerItemMetadata: [AVMetadataItem]?) {
    let title = playerItemMetadata?.first { $0.identifier == .commonIdentifierTitle }?.stringValue ?? ""
    let artist = playerItemMetadata?.first {$0.identifier == .commonIdentifierArtist }?.stringValue ?? ""
    SharedMetadataIdentifier.setMetadata(title: title, artist: artist)
  }
}

@available(iOS 14.0, *)
extension RNVideoPlayerViewX : MediaPlayerControlsViewDelegate {
  func controlDidTap(_ control: MediaPlayerControlsView, controlType: MediaPlayerControlButtonType, didChangeControlEvent event: Any?) {
    switch controlType {
    case .playPause:
      switch mediaSource.playbackState {
      case .playing:
        mediaSource.setPlaybackState(to: .paused)
        sendEvent(.onMediaPlayPause, false)
        break
      case .paused:
        mediaSource.setPlaybackState(to: .playing)
        sendEvent(.onMediaPlayPause, true)
        break
      case .waiting:
        mediaSource.setPlaybackState(to: .playing)
        sendEvent(.onMediaPlayPause, true)
        break
      case .ended: mediaSource.setPlaybackState(to: .replay)
      case .error: break
      case .replay: break
      case .none:
        mediaSource.setPlaybackState(to: .playing)
        sendEvent(.onMediaPlayPause, true)
        break
      }
    case .fullscreen:
      if event as! Bool {
        playerLayerVC?.didPresentFullscreen()
      } else {
        playerLayerVC?.didDismissFullscreen()
      }
    case .optionsMenu:
      let values = event as! (String, Any)
      if (values.0 == "Speeds") {
        mediaSource.setRate(to: values.1 as! Float)
      }
//      sendEvent(.onMenuItemSelected, event)
    case .seekGestureForward:
      mediaSource.onForwardTime(event as! Int)
    case .seekGestureBackward:
      mediaSource.onBackwardTime(event as! Int)
    }
  }
  
  func sliderDidChange(_ control: MediaPlayerControlsView, didChangeProgressFrom fromValue: Double, didChangeProgressTo toValue: Double) {
    let lastProgressInSeconds = fromValue * (mediaSource.playerItem?.duration.seconds ?? 0)
    let progressInSeconds = toValue * (mediaSource.playerItem?.duration.seconds ?? 0)
    
    let sliderProgressInfo = ["start": ["percent": fromValue, "seconds": lastProgressInSeconds], "ended": ["percent": toValue, "seconds": progressInSeconds]]
    self.sendEvent(.onMediaSeekBar, sliderProgressInfo)
  }
}

//@available(iOS 14.0, *)
//class RNVideoPlayerView : UIView {
//  private var mediaSession: MediaSessionManager? = nil
//  private var eventsManager: RCTEvents? = nil
//  private var videoPlayerView: VideoPlayerViewController? = .none
//  private var player: AVPlayer? = nil
//
//  private var isInitialized = false
//  @objc var menus: NSDictionary? = [:]
//  @objc var thumbnails: NSDictionary? = [:]
//  
//  @objc var onMenuItemSelected: RCTBubblingEventBlock?
//  @objc var onMediaBuffering: RCTBubblingEventBlock?
//  @objc var onMediaReady: RCTBubblingEventBlock?
//  @objc var onMediaCompleted: RCTBubblingEventBlock?
//  @objc var onFullScreenStateChanged: RCTDirectEventBlock?
//  @objc var onMediaError: RCTDirectEventBlock?
//  @objc var onMediaBufferCompleted: RCTDirectEventBlock?
//  @objc var onMediaPlayPause: RCTDirectEventBlock?
//  @objc var onMediaRouter: RCTDirectEventBlock?
//  @objc var onMediaSeekBar: RCTDirectEventBlock?
//  @objc var onMediaPinchZoom: RCTDirectEventBlock?
//
//  @objc var entersFullScreenWhenPlaybackBegins: Bool = false
//  @objc var controlsStyles: NSDictionary? = [:]
//  @objc var tapToSeek: NSDictionary? = [:]
////  
////  @objc var source: NSDictionary? = [:] {
////    didSet { setup() }
////  }
//  
//  @objc var rate: Float = 0.0 {
//    didSet {
//      adjustPlaybackRate(to: rate)
//    }
//  }
//  
//  @objc var replaceMediaUrl: String = "" {
//    didSet {
//      let url = replaceMediaUrl
//      if (url.isEmpty) { return }
//      updatePlayerWithNewURL(url)
//    }
//  }
//  
//  @objc var autoPlay: Bool = false {
//    didSet {
//      if autoPlay {
//        appConfig.shouldAutoPlay = true
//      }
//    }
//  }
//  
//  override init(frame: CGRect) {
//    super.init(frame: frame)
//  }
//  
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
//  
//  @objc var resizeMode: NSString = "contain"
//  
//  
////  private func setup() {
////    appConfig.isLoggingEnabled.toggle()
////    mediaPlayerVC = MediaPlayerAdapterView()
////    mediaPlayerVC?.setup(with: source)
////
////    if let wrapper = mediaPlayerVC {
////      wrapper.frame = bounds
////      addSubview(wrapper)
////    }
////  }
//  
//  private func setupPlayer() {
//    mediaSession = MediaSessionManager()
//    mediaSession?.entersFullScreenWhenPlaybackBegins = entersFullScreenWhenPlaybackBegins
//    guard let mediaSession else { return }
//    videoPlayerView?.releaseResources()
//    guard let urlString = source?["url"] as? String,
//          let videoURL = URL(string: urlString) else {
//      return
//    }
//    let startTime = source?["startTime"] as? Double ?? 0
//    
//    DispatchQueue.main.async { [self] in
//      self.player = AVPlayer(url: videoURL)
//      self.player?.seek(to: CMTime(seconds: startTime, preferredTimescale: 1))
//      
//      if self.autoPlay == true {
//          self.player?.play()
//      }
//      
//      if let metadata = source?["metadata"] as? NSDictionary {
//        player?.currentItem!.externalMetadata = createMetadata(for: metadata)
//      }
//      
//      if let tapToSeek {
//        guard let suffix = tapToSeek["suffixLabel"] as? String,
//              let value = tapToSeek["value"] as? Int else { return }
//        mediaSession.tapToSeek = (value, suffix)
//      }
//      
//      if let player {
//        eventsManager =  RCTEvents(
//          onVideoProgress: onMediaBuffering,
//          onError: onMediaError,
//          onCompleted: onMediaCompleted,
//          onFullscreen: onFullScreenStateChanged,
//          onPlayPause: onMediaPlayPause,
//          onMediaRouter: onMediaRouter,
//          onSeekBar: onMediaSeekBar,
//          onReady: onMediaReady,
//          onPinchZoom: onMediaPinchZoom,
//          onMenuItemSelected: onMenuItemSelected
//        )
//        eventsManager?.setupNotifications()
//        
//        videoPlayerView = VideoPlayerViewController(player: player, mediaSession: mediaSession, menus: menus)
//        if let wrapper = videoPlayerView?.view {
//          addSubview(wrapper)
//        }
//      }
//      
//      mediaSession.makeNowPlayingInfo()
//      mediaSession.setupRemoteCommandCenter()
//      mediaSession.setupPlayerObservation()
//      if let thumbnails {
//        mediaSession.thumbnailsDictionary = thumbnails
//      }
//    }
//  }
//  
//  private func createMetadata(for source: NSDictionary?) -> [AVMetadataItem] {
//    var metadataItems: [AVMetadataItem] = []
//    
//    if let source {
//      for (key, value) in source {
//        guard let keyString = key as? String,
//              let valueString = value as? String else {
//            continue
//        }
//        
//        guard let identifier = mapKeyToMetadataIdentifier(keyString) else { continue }
//        
//        let metadataItem = AVMutableMetadataItem()
//        metadataItem.identifier = identifier
//        metadataItem.value = valueString as NSString
//        metadataItem.locale = Locale.current
//        
//        metadataItems.append(metadataItem)
//      }
//    }
//    
//    return metadataItems
//  }
//  
//  private func mapKeyToMetadataIdentifier(_ key: String) -> AVMetadataIdentifier? {
//      switch key {
//      case "title":
//          return .commonIdentifierTitle
//      case "artist":
//          return .commonIdentifierArtist
//      case "albumName":
//          return .commonIdentifierAlbumName
//      default:
//          return nil
//      }
//  }
//  
//  override func layoutSubviews() {
////    videoPlayerView?.view.frame = bounds
//    mediaPlayerVC?.frame = bounds
//    super.layoutSubviews()
//  }
//  
//  override func removeFromSuperview() {
//    videoPlayerView?.releaseResources()
//  }
//  
//  @objc private func updatePlayerWithNewURL(_ url: String) {
//    let newUrl = URL(string: url)
//
//    if (newUrl == mediaSession?.urlOfCurrentPlayerItem()) {
//      return
//    }
//    
//    let currentTime = mediaSession?.player?.currentItem?.currentTime() ?? CMTime.zero
//    let asset = AVURLAsset(url: newUrl!)
//    let newPlayerItem = AVPlayerItem(asset: asset)
//    
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [self] in
//      eventsManager?.setupNotifications()
//      
//      player?.replaceCurrentItem(with: newPlayerItem)
//      player?.seek(to: currentTime)
//    
//      var playerItemStatusObservation: NSKeyValueObservation?
//      playerItemStatusObservation = newPlayerItem.observe(\.status, options: [.new]) { (item, _) in
//        NotificationCenter.default.post(name: .AVPlayerErrors, object: extractPlayerItemError(item))
//        guard item.status == .readyToPlay else {
//          return
//        }
//        playerItemStatusObservation?.invalidate()
//      }
//    })
//  }
//  
//  @objc private func adjustPlaybackRate(to rate: Float) {
//    mediaSession?.newRate = rate
//    DispatchQueue.main.async(execute: { [self] in
//      if (self.player?.timeControlStatus == .playing) {
//        self.player?.rate = rate
//      }
//    })
//  }
//}

//@available(iOS 14.0, *)
//extension RNVideoPlayerView {
//  func videoGravity(_ videoResize: Resize) -> AVLayerVideoGravity  {
//    switch (videoResize) {
//    case .stretch:
//      return .resize
//    case .cover:
//      return .resizeAspectFill
//    case .contain:
//      return .resizeAspect
//    }
//  }
//}
