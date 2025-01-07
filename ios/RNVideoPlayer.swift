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
  
  fileprivate var mediaPlayer: MediaPlayerAdapterView?
  fileprivate var mediaPlayerControlView: MediaPlayerControlView?
  fileprivate var isFullscreen: Bool = false
  fileprivate var observable: MediaPlayerObservable? = MediaPlayerObservable()

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
  
  @objc var rate: Float = 0.0 {
    didSet {
      if let mediaPlayer {
        appConfig.log("rate \(rate)")
      }
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
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    // This ensure that layout not change when player stay on fullscreen controller.
    if (!isFullscreen) {
      playerSource?.frame = bounds
      mediaPlayer?.frame = bounds
    }
    
    mediaPlayerControlView?.view?.frame = bounds
    super.layoutSubviews()
  }
  
  deinit {
//    mediaPlayer?.release()
//    mediaPlayer = nil
//    mediaPlayerControlView = nil
//    observable = nil
    playerSource = nil
  }
  
  private func setup() {
    appConfig.isLoggingEnabled.toggle()
    playerSource = PlayerSource()
//    observable = MediaPlayerObservable()
//    mediaPlayer = MediaPlayerAdapterView()
//    mediaPlayerControlView = MediaPlayerControlView(observable: observable!)
//    
//    mediaPlayerControlView?.mediaPlayerAdapter = mediaPlayer
//    mediaPlayerControlView?.delegate = self
//    
//    mediaPlayer?.delegate = self
//
//    mediaPlayer!.frame = bounds
//    mediaPlayerControlView?.view.frame = bounds
//    
//    insertSubview(mediaPlayer!, at: 0)
//    insertSubview(mediaPlayerControlView!.view, at: 1)
    if let playerSource {
      insertSubview(playerSource, at: 0)
    }
  }
}

//@available(iOS 14.0, *)
//extension RNVideoPlayerViewX: MediaPlayerAdapterViewDelegate, MediaPlayerControlViewDelegate {  
//  func controlView(_ controlView: MediaPlayerControlView, didButtonPressed buttonType: MediaPlayerControlButtonType, actionState: MediaPlayerControlActionState?, actionValues: Any?) {
//    switch buttonType {
//    case .playPause:
//      switch mediaPlayer?.playbackState {
//      case .playing:
//        mediaPlayer?.onPause()
//      case .paused:
//        mediaPlayer?.onPlay()
//      case .stopped: break
//        // TODO: need implementation
//      case .ended:
//        mediaPlayer?.onReplay()
//      case .error: break
//        // TODO: need implementation
//      case nil: break
//        //
//      }
//      observable?.updateIsPlaying(to: mediaPlayer!.isPlaying)
//      
//    case .fullscreen:
//      isFullscreen = actionState == .fullscreenActive
//      observable?.updateIsFullScreen(to: isFullscreen)
//    case .optionsMenu:
//      let values = actionValues as! (String, Any)
//      onMenuItemSelected?(["name": values.0, "value": values.1])
//    }
//  }
//  
//  func controlView(_ controlView: MediaPlayerControlView, didChangeFrom fromValue: Double, didChangeTo toValue: CMTime) {
//    mediaPlayer?.seekTo(with: toValue) { [self] finished in
//      // need add schedule
//      if  finished {
////        observable?.updateIsSeeking(to: false)
//      }
//    }
//  }
//  
//  
//  func mediaPlayer(_ player: MediaPlayerAdapterView, didFinishPlayingWithError error: (any Error)?) {
//    //
//  }
//  
//  func mediaPlayer(_ player: MediaPlayerAdapterView, didChangePlaybackState state: PlaybackState) {
//    appConfig.log("playbackState: \(state)")
//    observable?.updateIsPlaying(to: state == .playing)
//    //
//  }
//  
//  func mediaPlayer(_ player: MediaPlayerAdapterView, didChangePlaybackTime currentTime: TimeInterval, loadedTimeRanges: TimeInterval, diChangePlaybackDuration duration: TimeInterval) {
//    guard duration > 0,
//          !duration.isNaN,
//          !currentTime.isNaN,
//          loadedTimeRanges >= 0,
//          !loadedTimeRanges.isNaN else {
//      appConfig.log("Invalid values for progress calculation. Duration: \(duration), CurrentTime: \(currentTime), LoadedTimeRanges: \(loadedTimeRanges)")
//      return
//    }
//    
//    let sliderProgressValue = currentTime / duration
//    let bufferingProgressValue = loadedTimeRanges / duration
////    observable?.updateSeekBar(sliderProgressValue: sliderProgressValue, bufferingProgressValue: bufferingProgressValue)
////    observable?.updateMediaTimeValues(currentTimeValue: currentTime, duration: duration)
//    
//  }
//  
//  func mediaPlayer(_ player: MediaPlayerAdapterView, duration: TimeInterval) {
//    appConfig.log("duration: \(duration)")
//    //
//  }
//  
//  func mediaPlayer(_ player: MediaPlayerAdapterView, mediaDidChangePlaybackRate rate: Float) {
//    //
//  }
//  
//  func mediaPlayer(_ player: MediaPlayerAdapterView, mediaIsPlayingDidChange isPlaying: Bool) {
//    //
//  }
//  
//  func mediaPlayer(_ player: MediaPlayerAdapterView, didChangeReadyToDisplay isReadyToDisplay: Bool) {
//    observable?.updateIsReadyToDisplay(to: isReadyToDisplay)
//  }
//  
//  func mediaPlayer(_ player: MediaPlayerAdapterView, didFailWithError error: (any Error)?) {
//    appConfig.log("didFailWithError: \(error?.localizedDescription)")
//  }
//}

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
    didSet {
//      setupPlayer()
      setup()
    }
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
