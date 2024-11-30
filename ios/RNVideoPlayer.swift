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
  private var mediaSession: MediaSessionManager? = nil
  private var eventsManager: RCTEvents? = nil
  private var videoPlayerView: VideoPlayerViewController? = .none
  private var player: AVPlayer? = nil
  
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
  @objc var onReady: RCTBubblingEventBlock?
  @objc var onCompleted: RCTBubblingEventBlock?
  @objc var onFullscreen: RCTDirectEventBlock?
  @objc var onError: RCTDirectEventBlock?
  @objc var onBuffer: RCTDirectEventBlock?
  @objc var onBufferCompleted: RCTDirectEventBlock?
//  @objc var onVideoDownloaded: RCTDirectEventBlock?
//  @objc var onDownloadVideo: RCTDirectEventBlock?
  @objc var onPlayPause: RCTDirectEventBlock?
  @objc var onMediaRouter: RCTDirectEventBlock?
  @objc var onSeekBar: RCTDirectEventBlock?
  @objc var onPinchZoom: RCTDirectEventBlock?
  
  @objc var entersFullScreenWhenPlaybackBegins: Bool = false
  
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
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc var resizeMode: NSString = "contain"
  
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
          onVideoProgress: onVideoProgress,
          onError: onError,
          onBuffer: onBuffer,
          onCompleted: onCompleted,
          onFullscreen: onFullscreen,
          onPlayPause: onPlayPause,
          onMediaRouter: onMediaRouter,
          onSeekBar: onSeekBar,
          onReady: onReady,
          onPinchZoom: onPinchZoom,
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
  
  override func layoutSubviews() {
    videoPlayerView?.view.frame = bounds
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
