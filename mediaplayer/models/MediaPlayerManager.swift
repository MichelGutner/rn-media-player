//
//  MediaPlayerManager.swift
//  rn-media-player
//
//  Created by Michel Gutner on 06/01/25.
//

import AVFoundation
import Combine


public enum PlaybackState : Int {
  case playing = 1
  case paused = 2
  case waiting = 0
  case ended = 3
  case error = 4
  case replay = 5
}

public protocol PlayerSourceViewDelegate : AnyObject {
  func mediaPlayer(_ player: PlayerSource, didFinishPlayingWithError error: Error?)
  func mediaPlayer(_ player: PlayerSource, didChangePlaybackState state: PlaybackState)
  func mediaPlayer(_ player: PlayerSource, duration: TimeInterval)
  func mediaPlayer(_ player: PlayerSource, mediaDidChangePlaybackRate rate: Float)
  func mediaPlayer(_ player: PlayerSource, didChangeReadyToDisplay isReadyToDisplay: Bool)
  func mediaPlayer(_ player: PlayerSource, didFailWithError error: (any Error)?)
}


open class PlayerSource {
  fileprivate var startTime: Double = 0.0
  fileprivate var lastPlayerItem: AVPlayerItem?
  fileprivate let audioManager = MediaPlayerAudioManager()
  fileprivate var cancellables: Set<AnyCancellable> = []
  
  fileprivate var playbackRate: Float = 1.0 {
    didSet {
      if oldValue != playbackRate {
        appConfig.log("[PlayerSource] Changing playback rate to \(playbackRate)")
        if playbackState == .playing {
          player?.rate = playbackRate
        }
      }
    }
  }
  
  open var playbackState: PlaybackState = .paused {
    didSet {
      if oldValue != playbackState {
        switch playbackState {
        case .playing: onPlay()
        case .paused: onPause()
        case .replay: onReplay()
        case .waiting: break
        case .ended: break
          // implement if need call loop video
//          onReplay()
        case .error: break
        }
        delegate?.mediaPlayer(self, didChangePlaybackState: playbackState)
      }
    }
  }
  
  init() {}

  open weak var delegate: PlayerSourceViewDelegate?
  
  open var playerItem: AVPlayerItem? {
    didSet {
      didChangePlayerItem()
    }
  }
  
  open weak var player: AVPlayer?
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open var assetURL: URL? {
    guard let player else { return nil }
    return (player.currentItem?.asset as? AVURLAsset)?.url
  }
  
  open var isReady: Bool = false {
    didSet {
      if oldValue != isReady {
        delegate?.mediaPlayer(self, didChangeReadyToDisplay: isReady)
      }
    }
  }
  
  open func onPlay() {
    guard let player else { return }
    player.play()
    // This ensure that player layer not lock when playback returned from paused
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [self] in
      player.rate = playbackRate
    })
  }
  
  open func onPause() {
    guard let player else { return }
    player.pause()
    playbackState = .paused
  }
  
  open func onReplay() {
    guard let player else { return }
    player.seek(to: .zero)
    player.play()
    playbackState = .playing
  }
  
  open func onBackwardTime(_ targetTime: Int) {
    guard let player else { return }
    guard let currentItem = player.currentItem else { return }
    let currentTime = CMTimeGetSeconds(player.currentTime())
    let newTime = max(currentTime - Double(targetTime), 0)
    
    if newTime < currentItem.duration.seconds, playbackState == .ended {
      playbackState = .playing
    }
    
    player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                toleranceBefore: .zero,
                toleranceAfter: .zero,
                completionHandler: { _ in })
  }
  
  open func onForwardTime(_ targetTime: Int) {
    guard let player else { return }
    guard let currentItem = player.currentItem else { return }
    
    let currentTime = CMTimeGetSeconds(player.currentTime())
    let newTime = max(currentTime + Double(targetTime), 0)
    
    player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                toleranceBefore: .zero,
                toleranceAfter: .zero,
                completionHandler: { _ in })
  }
  
  open func setPlaybackState(to state: PlaybackState) {
    playbackState = state
  }
  
  open func setRate(to rate: Float) {
    self.playbackRate = rate
  }
  
  open func setIsReadyToPlay(_ isReady: Bool) {
    self.isReady = isReady
  }
  
  fileprivate func didChangePlayerItem() {
    if lastPlayerItem == playerItem {
      return
    }
    
    if let item = playerItem {
      NotificationCenter.default.addObserver(self, selector: #selector(didFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: item)
    }
    
    lastPlayerItem = playerItem
  }
  
  @objc fileprivate func didFinishPlaying() {
    if playbackState != .ended {
      if let playerItem = playerItem {
        delegate?.mediaPlayer(self, duration: CMTimeGetSeconds(playerItem.duration))
      }
      
      self.playbackState = .ended
      appConfig.log("Media Player has finished playing.")
    }
  }

  internal func setup(with source: NSDictionary?, completionHandler: @escaping (_ player: AVPlayer) -> Void) {
    guard let urlString = source?["url"] as? String,
          let videoURL = URL(string: urlString) else {
      appConfig.log("Invalid URL or missing URL in source.")
      return
    }
    
    let startTime = source?["startTime"] as? Double ?? 0.0
    let externalMetadataDict = source?["metadata"] as? NSDictionary
    let autoStart = source?["autoStart"] as? Bool ?? false
    let metadata = MediaPlayerItemMetadataManager(metadata: externalMetadataDict)
    
    let newPlayerItem = AVPlayerItem(url: videoURL)
    newPlayerItem.externalMetadata = metadata.items
    
    let strongPlayer = AVPlayer(playerItem: newPlayerItem)
    strongPlayer.seek(to: CMTime(seconds: startTime, preferredTimescale: 600))
    completionHandler(strongPlayer)
    
    self.player = strongPlayer
    self.playerItem = newPlayerItem
    self.startTime = startTime
    
    if autoStart {
      setPlaybackState(to: .playing)
    }
    
    audioManager.activateAudioSession { isSuccess, error in
      if isSuccess {
        appConfig.log("[MediaPlayerManager] audio session activated successfully.")
      } else {
        appConfig.log("[MediaPlayerManager] failed to activate audio session: \(error)")
      }
    }
  }
  
  open func setPlayerWithNewURL(_ url: String, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
      guard let newUrl = URL(string: url) else {
          completion(false, NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "The provided URL is invalid."]))
          return
      }
      
      if newUrl == self.assetURL {
          return
      }
      
    let currentTime = player?.currentTime() ?? CMTime.zero
      let asset = AVURLAsset(url: newUrl)
      let newPlayerItem = AVPlayerItem(asset: asset)
      
      // Substitui o item atual no player
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
          guard let self = self else {
              completion(false, NSError(domain: "DeallocatedPlayer", code: 2, userInfo: [NSLocalizedDescriptionKey: "The player instance has been deallocated."]))
              return
          }
          
          self.player?.replaceCurrentItem(with: newPlayerItem)
          self.player?.seek(to: currentTime)
          
          var playerItemStatusObservation: NSKeyValueObservation?
          
          playerItemStatusObservation = newPlayerItem.observe(\.status, options: [.new]) { item, _ in
              if let error = item.error {
                  playerItemStatusObservation?.invalidate()
                  completion(false, error)
                  return
              }
              
              guard item.status == .readyToPlay else {
                  return
              }
              
              playerItemStatusObservation?.invalidate()
              completion(true, nil)
          }
      }
  }

  public func prepareToDeInit() {
    lastPlayerItem = nil
    playerItem = nil
    
    if let playerItem = lastPlayerItem {
      NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    player?.pause()
    player?.replaceCurrentItem(with: nil)
    player = nil
    
    
    
    audioManager.deactivateAudioSession { isSuccess, error in
      if isSuccess {
        print("Audio session deactivated successfully.")
      } else {
        print("Failed to deactivate audio session: \(error)")
      }
    }
    
    playbackState = .waiting
    isReady = false
  }
}

//extension PlayerSource {
//  fileprivate func addPlayerItemObservers(for item: AVPlayerItem) {
//    item.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
//  }
//  
//  fileprivate func removePlayerItemObservers(for item: AVPlayerItem) {
//    item.removeObserver(self, forKeyPath: "status")
//  }
//  
//  override open func observeValue(
//    forKeyPath keyPath: String?,
//    of object: Any?,
//    change: [NSKeyValueChangeKey : Any]?,
//    context: UnsafeMutableRawPointer?)
//  {
//    if keyPath == #keyPath(AVPlayer.status) {
//      if let playerItem = playerItem {
//        switch playerItem.status {
//        case .readyToPlay:
//          if appConfig.shouldAutoPlay {
//            player?.play()
//            playbackState = .playing
//          }
//          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.isReady = true
//          }
//          break
//        case .unknown:
//          self.playbackState = .waiting
//        case .failed:
//          self.delegate?.mediaPlayer(self, didFailWithError: playerItem.error)
//          self.playbackState = .error
//        @unknown default: break
//        }
//      }
//    }
//  }
//}

open class MediaPlayerAudioManager {
    fileprivate var audioSession = AVAudioSession.sharedInstance()
    fileprivate var errorDetails: [String: Any] = [:]
    
    open func activateAudioSession(onCompletion: @escaping (_ isSuccess: Bool, _ error: [String: Any]) -> Void) {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            onCompletion(true, [:])
        } catch let error as NSError {
            errorDetails = [
                NSLocalizedDescriptionKey: "Unable to activate the audio session.",
                NSLocalizedFailureReasonErrorKey: "An error occurred while activating the audio session.",
                NSLocalizedRecoverySuggestionErrorKey: "Check if another process is using the audio session or ensure the configuration is correct.",
                NSUnderlyingErrorKey: error
            ]
            onCompletion(false, errorDetails)
        }
    }
    
    open func deactivateAudioSession(onCompletion: @escaping (_ isSuccess: Bool, _ error: [String: Any]) -> Void) {
        do {
            try audioSession.setActive(false)
            onCompletion(true, [:])
        } catch let error as NSError {
            errorDetails = [
                NSLocalizedDescriptionKey: "Unable to deactivate the audio session.",
                NSLocalizedFailureReasonErrorKey: "An error occurred while deactivating the audio session.",
                NSLocalizedRecoverySuggestionErrorKey: "Ensure no other processes are holding the audio session.",
                NSUnderlyingErrorKey: error
            ]
            onCompletion(false, errorDetails)
        }
    }
}

open class MediaPlayerItemMetadataManager {
  private let metadataIdentifier: AVMetadataIdentifier? = nil
  private var metadata: NSDictionary
  open var items: [AVMetadataItem] = []
  
  init(metadata: NSDictionary?) {
    self.metadata = metadata ?? [:]
    processMetadata()
  }
  
  fileprivate func processMetadata() {
    for (key, value) in metadata {
      guard let keyString = key as? String,
            let valueString = value as? String else {
        continue
      }
      
      guard let identifier = mapKeyToMetadataIdentifier(keyString) else {
        continue
      }
      
      let metadataItem = AVMutableMetadataItem()
      metadataItem.identifier = identifier
      metadataItem.value = valueString as NSString
      metadataItem.locale = Locale.current
      
      items.append(metadataItem)
    }
  }
  
  fileprivate func mapKeyToMetadataIdentifier(_ key: String) -> AVMetadataIdentifier? {
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
}
