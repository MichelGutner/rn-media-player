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
  case none = 9
}

public protocol PlayerSourceViewDelegate : AnyObject {
  func mediaPlayer(_ player: PlayerSource, didChangePlaybackState state: PlaybackState)
  func mediaPlayer(_ player: PlayerSource, didChangeReadyToDisplay isReadyToDisplay: Bool)
  func mediaPlayer(_ player: PlayerSource, loadFail error: (any Error)?)
  func mediaPlayer(_ player: PlayerSource, playerItemMetadata: [AVMetadataItem]?)
  func mediaPlayer(_ control: PlayerSource, currentTime: Double, duration: Double, bufferingProgress: CGFloat)
}

open class PlayerSource {
  fileprivate var startTime: Double = 0.0
  fileprivate var lastPlayerItem: AVPlayerItem?
  fileprivate let audioManager = MediaPlayerAudioManager()
  fileprivate var cancellables: Set<AnyCancellable> = []
  fileprivate var timeObserver: Any?
  
  fileprivate var playbackRate: Float = 1.0 {
    didSet {
      if oldValue != playbackRate {
        appConfig.log("[MediaPlayerManager] Changing playback rate to \(playbackRate)")
        if playbackState == .playing {
          player?.rate = playbackRate
        }
      }
    }
  }
  
  open var playbackState: PlaybackState = .none {
    didSet {
      if oldValue != playbackState {
        appConfig.log("[MediaPlayerManager] Changing playback state to \(playbackState)")
        switch playbackState {
        case .playing: onPlay()
        case .paused: onPause()
        case .replay: onReplay()
        case .waiting: break
        case .ended: break
          // implement if need call loop video
//          onReplay()
        case .error: break
        case .none: break
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
  
  fileprivate func onPlay() {
    player?.play()
    // This ensure that player layer not freeze when playback returned from paused
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [self] in
      player?.rate = playbackRate > 0 ? playbackRate : 1
    })
  }
  
  fileprivate func onPause() {
    player?.pause()
  }
  
  fileprivate func onReplay() {
    player?.seek(to: .zero)
    player?.play()
    playbackState = .playing
  }
  
  open func onBackwardTime(_ targetTime: Int) {
    guard let player else { return }
    guard let currentItem = player.currentItem, targetTime > 0 else { return }
    let currentTime = CMTimeGetSeconds(player.currentTime())
    let newTime = currentTime - Double(targetTime)

    player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                toleranceBefore: .zero,
                toleranceAfter: .zero,
                completionHandler: { _ in })
    
    if newTime < currentItem.duration.seconds, playbackState == .ended {
      playbackState = .playing
    }
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
    appConfig.log("PlayerSource setPlaybackState to \(state)")
    playbackState = state
  }
  
  open func setRate(to rate: Float) {
    if (rate.isZero) {
      setPlaybackState(to: .waiting)
    }
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
      delegate?.mediaPlayer(self, playerItemMetadata: playerItem?.externalMetadata ?? [])
      NotificationCenter.default.addObserver(self, selector: #selector(didFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: item)
    }
    
    lastPlayerItem = playerItem
    addPlayerItemObserve()
  }
  
  @objc fileprivate func didFinishPlaying() {
    if playbackState != .ended {
      self.playbackState = .ended
      appConfig.log("[MediaPlayerManager] Media Player has finished playing.")
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
    let metadata = MediaPlayerItemMetadataManager(metadata: externalMetadataDict)
    
    let newPlayerItem = AVPlayerItem(url: videoURL)
    newPlayerItem.externalMetadata = metadata.items
    
    let strongPlayer = AVPlayer(playerItem: newPlayerItem)
    strongPlayer.seek(to: CMTime(seconds: startTime, preferredTimescale: 600))
    completionHandler(strongPlayer)
    
    self.player = strongPlayer
    self.playerItem = newPlayerItem
    self.startTime = startTime
    
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
        completion(false, nil)
          return
      }
      
      let currentTime = player?.currentTime() ?? .zero
      let asset = AVURLAsset(url: newUrl)
      let newPlayerItem = AVPlayerItem(asset: asset)
    
    asset.loadValuesAsynchronously(forKeys: ["playable"]) { [weak self] in
          guard let self = self else {
              completion(false, NSError(domain: "DeallocatedPlayer", code: 2, userInfo: [NSLocalizedDescriptionKey: "The player instance has been deallocated."]))
              return
          }
          
          var error: NSError?
          let status = asset.statusOfValue(forKey: "playable", error: &error)
          
          guard status == .loaded else {
              DispatchQueue.main.async {
                  completion(false, error ?? NSError(domain: "AssetNotPlayable", code: 3, userInfo: [NSLocalizedDescriptionKey: "The asset is not playable."]))
              }
              return
          }
          
          DispatchQueue.main.async {
              self.player?.replaceCurrentItem(with: newPlayerItem)
              self.player?.seek(to: currentTime, toleranceBefore: .zero, toleranceAfter: .zero)
            
              var playerItemStatusObservation: NSKeyValueObservation?
              playerItemStatusObservation = newPlayerItem.observe(\.status, options: [.new]) { item, _ in
                  if let itemError = item.error {
                      playerItemStatusObservation?.invalidate()
                      completion(false, itemError)
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
  }
  
  fileprivate func addPlayerItemObserve() {
    player?.currentItem?.publisher(for: \.status)
      .receive(on: DispatchQueue.main)
      .sink { [self] status in
        switch status {
        case .failed:
          self.delegate?.mediaPlayer(self, loadFail: player?.currentItem?.error)
        case .unknown: break
        case .readyToPlay:
          self.delegate?.mediaPlayer(self, didChangeReadyToDisplay: true)
          break
        @unknown default: break
        }
      }.store(in: &cancellables)
    
    timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 2), queue: .main) { [weak self] time in
      guard let self = self else { return }
      guard let timeRanges = self.playerItem?.loadedTimeRanges else { return }
      
      if self.playbackState == .paused { return }
      if let firstTimeRange = timeRanges.first?.timeRangeValue {
        let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
        let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
        let totalBuffering = bufferedStart + bufferedDuration
        self.delegate?.mediaPlayer(self, currentTime: time.seconds, duration: (playerItem?.duration.seconds ?? 0), bufferingProgress: totalBuffering)
      }
    }
  }
  
  public func prepareToDeInit() {
    if let timeObserver {
      appConfig.log("[PlayerSource] Removed time observer.")
      player?.removeTimeObserver(timeObserver)
    }
    
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
