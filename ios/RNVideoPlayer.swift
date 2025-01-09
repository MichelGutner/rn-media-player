import AVKit
import SwiftUI
import UIKit
import React
import AVFoundation

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

//public class RCTEventDispatcher: NSObject {
//  @objc var onMediaCompleted: RCTBubblingEventBlock?
//  public func sendEvent(_ event: RCTEvent) {
//    Swift.print("Event: \(event)")
//  }
//  @objc public func sendOnMediaBufferCompletedEvent() {
//    Swift.print("Event: onMediaCompleted")
//    onMediaCompleted?(["completed": true as Any])
//  }
//}

@available(iOS 14.0, *)
class RNVideoPlayerViewX : UIView {
  fileprivate var playerSource: PlayerSource?
  fileprivate var mediaPlayerControlView: MediaPlayerControlView?
  
  @objc var onMenuItemSelected: RCTBubblingEventBlock?
  @objc var onMediaBuffering: RCTBubblingEventBlock?
  @objc var onMediaReady: RCTBubblingEventBlock?
  @objc var onMediaCompleted: RCTBubblingEventBlock?
  @objc var onFullScreenStateChanged: RCTDirectEventBlock?
  @objc var onMediaError: RCTDirectEventBlock?
  @objc var onMediaBufferCompleted: RCTDirectEventBlock?
  @objc var onMediaPlayPause: RCTDirectEventBlock?
  @objc var onMediaRouter: RCTDirectEventBlock?
  @objc var onMediaSeekBar: RCTDirectEventBlock?
  @objc var onMediaPinchZoom: RCTDirectEventBlock?

  @objc var entersFullScreenWhenPlaybackBegins: Bool = false
  @objc var controlsStyles: NSDictionary? = [:]
  @objc var tapToSeek: NSDictionary? = [:]
  
  @objc var rate: Float = 0.0 {
    didSet {
//      if let playerSource {
//        appConfig.log("rate \(rate)")
//      }
      playerSource?.setRate(to: rate)
    }
  }
  
  @objc var replaceMediaUrl: String = "" {
    didSet {
      let url = replaceMediaUrl
      if (url.isEmpty) { return }
//      updatePlayerWithNewURL(url)
    }
  }
  
  @objc var autoPlay: Bool = false {
    didSet {
      appConfig.shouldAutoPlay = autoPlay
    }
  }
  
  @objc var source: NSDictionary? = [:] {
    didSet {
      playerSource?.setup(with: source)
    }
  }
  
  @objc var menus: NSDictionary? = [:] {
    didSet {
      appConfig.playbackMenu = menus
    }
  }
  
  @objc var thumbnails: NSDictionary? = [:] {
    didSet {
      appConfig.thumbnails = thumbnails
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    // This ensure that layout not change when player stay on fullscreen controller.
    if (!ScreenStateObservable.shared.isFullScreen) {
      playerSource?.frame = bounds
    }
    mediaPlayerControlView?.view?.frame = bounds
    super.layoutSubviews()
  }
  
  deinit {
      playerSource?.prepareToDeInit()
//      PlaybackStateObservable.shared.cancellables.removeAll()
  }
  
  private func setup() {
    appConfig.isLoggingEnabled.toggle()
    playerSource = PlayerSource()
    
    playerSource?.delegate = self
    mediaPlayerControlView = MediaPlayerControlView()
    mediaPlayerControlView?.delegate = self
    
    if let playerSource, let mediaPlayerControlView {
      insertSubview(playerSource, at: 0)
      insertSubview(mediaPlayerControlView.view, at: 1)
    }
  }
}

@available(iOS 14.0, *)
extension RNVideoPlayerViewX: PlayerSourceViewDelegate {
  func mediaPlayer(_ player: PlayerSource, mediaIsPlayingDidChange isPlaying: Bool) {
//    PlaybackStateObservable.updateIsPlaying(to: isPlaying)
  }
  
  func mediaPlayer(_ player: PlayerSource, didChangeReadyToDisplay isReadyToDisplay: Bool) {
    PlaybackStateObservable.updateIsReady(to: isReadyToDisplay)
  }
  
  func mediaPlayer(_ player: PlayerSource, didFinishPlayingWithError error: (any Error)?) {
    //
  }
  
  func mediaPlayer(_ player: PlayerSource, duration: TimeInterval) {
    //
  }
  
  func mediaPlayer(_ player: PlayerSource, mediaDidChangePlaybackRate rate: Float) {
    //
  }
  
  func mediaPlayer(_ player: PlayerSource, didFailWithError error: (any Error)?) {
    //
  }
  
  func mediaPlayer(_ player: PlayerSourceViewDelegate, didFinishPlayingWithError error: (any Error)?) {
    //
  }
  
  func mediaPlayer(_ player: PlayerSource, didChangePlaybackState state: PlaybackState) {
    appConfig.log("File RNVideoPlayer Line: 160 PlaybackState -> \(state)")
    PlaybackStateObservable.updateIsPlaying(to: state == .playing)
  }
}

@available(iOS 14.0, *)
extension RNVideoPlayerViewX : MediaPlayerControlViewDelegate {
  func controlView(_ controlView: MediaPlayerControlView, didChangeProgressFrom fromValue: Double, didChangeProgressTo toValue: Double) {
    if toValue < 1, playerSource?.playbackState == .ended {
      playerSource?.setPlaybackState(to: .playing)
    }
    appConfig.log("Seeking fromValue \(fromValue) toValue \(toValue)")
  }
  
  func controlView(_ controlView: MediaPlayerControlView, didButtonPressed buttonType: MediaPlayerControlButtonType, actionState: MediaPlayerControlActionState?, actionValues: Any?) {
    switch buttonType {
    case .playPause:
      switch playerSource?.playbackState {
        case .playing: playerSource?.setPlaybackState(to: .paused)
        case .paused: playerSource?.setPlaybackState(to: .playing)
        case .waiting: break
        case .ended: playerSource?.setPlaybackState(to: .replay)
        case .error: break
        case .replay: break
        case nil: break
      }
    case .fullscreen:
      ScreenStateObservable.updateIsFullScreen(to: actionState == .fullscreenActive)
    case .optionsMenu:
      let values = actionValues as! (String, Any)
      onMenuItemSelected?(["name": values.0, "value": values.1])
    case .seekGestureForward:
      playerSource?.onForwardTime(actionValues as! Int)
    case .seekGestureBackward:
      playerSource?.onBackwardTime(actionValues as! Int)
    }
  }

}

@available(iOS 14.0, *)
class RNVideoPlayerView : UIView {
  private var mediaPlayerAdapter = MediaPlayerAdapterView()
  private var mediaPlayerVC: MediaPlayerAdapterView? = nil
  
  private var mediaSession: MediaSessionManager? = nil
  private var eventsManager: RCTEvents? = nil
  private var videoPlayerView: VideoPlayerViewController? = .none
  private var player: AVPlayer? = nil

  private var isInitialized = false
  @objc var menus: NSDictionary? = [:]
  @objc var thumbnails: NSDictionary? = [:]
  
  @objc var onMenuItemSelected: RCTBubblingEventBlock?
  @objc var onMediaBuffering: RCTBubblingEventBlock?
  @objc var onMediaReady: RCTBubblingEventBlock?
  @objc var onMediaCompleted: RCTBubblingEventBlock?
  @objc var onFullScreenStateChanged: RCTDirectEventBlock?
  @objc var onMediaError: RCTDirectEventBlock?
  @objc var onMediaBufferCompleted: RCTDirectEventBlock?
  @objc var onMediaPlayPause: RCTDirectEventBlock?
  @objc var onMediaRouter: RCTDirectEventBlock?
  @objc var onMediaSeekBar: RCTDirectEventBlock?
  @objc var onMediaPinchZoom: RCTDirectEventBlock?

  @objc var entersFullScreenWhenPlaybackBegins: Bool = false
  @objc var controlsStyles: NSDictionary? = [:]
  @objc var tapToSeek: NSDictionary? = [:]
  
  @objc var source: NSDictionary? = [:] {
    didSet { setup() }
  }
  
  @objc var rate: Float = 0.0 {
    didSet {
      adjustPlaybackRate(to: rate)
    }
  }
  
  @objc var replaceMediaUrl: String = "" {
    didSet {
      let url = replaceMediaUrl
      if (url.isEmpty) { return }
      updatePlayerWithNewURL(url)
    }
  }
  
  @objc var autoPlay: Bool = false {
    didSet {
      if autoPlay {
        appConfig.shouldAutoPlay = true
      }
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc var resizeMode: NSString = "contain"
  
  
  private func setup() {
    appConfig.isLoggingEnabled.toggle()
    mediaPlayerVC = MediaPlayerAdapterView()
    mediaPlayerVC?.setup(with: source)

    if let wrapper = mediaPlayerVC {
      wrapper.frame = bounds
      addSubview(wrapper)
    }
  }
  
  private func setupPlayer() {
    mediaSession = MediaSessionManager()
    mediaSession?.entersFullScreenWhenPlaybackBegins = entersFullScreenWhenPlaybackBegins
    guard let mediaSession else { return }
    videoPlayerView?.releaseResources()
    guard let urlString = source?["url"] as? String,
          let videoURL = URL(string: urlString) else {
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
      
      if let tapToSeek {
        guard let suffix = tapToSeek["suffixLabel"] as? String,
              let value = tapToSeek["value"] as? Int else { return }
        mediaSession.tapToSeek = (value, suffix)
      }
      
      if let player {
        eventsManager =  RCTEvents(
          onVideoProgress: onMediaBuffering,
          onError: onMediaError,
          onCompleted: onMediaCompleted,
          onFullscreen: onFullScreenStateChanged,
          onPlayPause: onMediaPlayPause,
          onMediaRouter: onMediaRouter,
          onSeekBar: onMediaSeekBar,
          onReady: onMediaReady,
          onPinchZoom: onMediaPinchZoom,
          onMenuItemSelected: onMenuItemSelected
        )
        eventsManager?.setupNotifications()
        
        videoPlayerView = VideoPlayerViewController(player: player, mediaSession: mediaSession, menus: menus)
        if let wrapper = videoPlayerView?.view {
          addSubview(wrapper)
        }
      }
      
      mediaSession.makeNowPlayingInfo()
      mediaSession.setupRemoteCommandCenter()
      mediaSession.setupPlayerObservation()
      if let thumbnails {
        mediaSession.thumbnailsDictionary = thumbnails
      }
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
  
  override func layoutSubviews() {
//    videoPlayerView?.view.frame = bounds
    mediaPlayerVC?.frame = bounds
    super.layoutSubviews()
  }
  
  override func removeFromSuperview() {
    videoPlayerView?.releaseResources()
  }
  
  @objc private func updatePlayerWithNewURL(_ url: String) {
    let newUrl = URL(string: url)

    if (newUrl == mediaSession?.urlOfCurrentPlayerItem()) {
      return
    }
    
    let currentTime = mediaSession?.player?.currentItem?.currentTime() ?? CMTime.zero
    let asset = AVURLAsset(url: newUrl!)
    let newPlayerItem = AVPlayerItem(asset: asset)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [self] in
      eventsManager?.setupNotifications()
      
      player?.replaceCurrentItem(with: newPlayerItem)
      player?.seek(to: currentTime)
    
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
    mediaSession?.newRate = rate
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
