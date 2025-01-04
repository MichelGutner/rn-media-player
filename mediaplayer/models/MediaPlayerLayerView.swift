//
//  MediaPlayerImpl.swift
//  Pods
//
//  Created by Michel Gutner on 03/01/25.
//

import Foundation
import AVFoundation

public enum PlaybackState {
  case playing
  case paused
  case stopped
  case ended
  case error
}

public protocol MediaPlayerLayerViewDelegate : AnyObject {
  func mediaPlayer(_ player: MediaPlayerLayerView, didFinishPlayingWithError error: Error?)
  func mediaPlayer(_ player: MediaPlayerLayerView, didChangePlaybackState state: PlaybackState)
  func mediaPlayer(_ player: MediaPlayerLayerView, duration: TimeInterval)
  func mediaPlayer(_ player: MediaPlayerLayerView, didChangePlaybackTime currentTime: TimeInterval, loadedTimeRanges timeRanges: TimeInterval)
  func mediaPlayer(_ plauer: MediaPlayerLayerView, mediaDidChangePlaybackRate rate: Float)
  func mediaPlayer(_ plauer: MediaPlayerLayerView, mediaIsPlayingDidChange isPlaying: Bool)
  func mediaPlayer(_ plauer: MediaPlayerLayerView, didFailWithError error: (any Error)?)
}

open class MediaPlayerLayerView : UIView {
  open weak var delegate: MediaPlayerLayerViewDelegate?
  fileprivate var playerLayer: AVPlayerLayer?
  fileprivate var lastPlayerItem: AVPlayerItem?
  fileprivate var timeObserver: Any? = nil
  
  open var playerItem: AVPlayerItem? {
    didSet {
      onPlayerItemDidChange()
    }
  }
  
  open lazy var player: AVPlayer? = {
    if let item = playerItem {
      let player = AVPlayer(playerItem: item)
      return player
    }
    return nil
  }()
  
  open var isPlaying: Bool = false {
    didSet {
      if oldValue != isPlaying {
        delegate?.mediaPlayer(self, mediaIsPlayingDidChange: isPlaying)
      }
    }
  }
  
  open var assetURL: URL? {
    guard let player else { return nil }
    return (player.currentItem?.asset as? AVURLAsset)?.url
  }
  
  open func setupPlayer(with source: NSDictionary?) {
    guard let urlString = source?["url"] as? String,
          let videoURL = URL(string: urlString) else {
      return
    }
    
    let startTime = source?["startTime"] as? Double ?? 0
    let metadata = source?["metadata"] as? NSDictionary
    DispatchQueue.main.async {
      MediaPlayerManager.buildPlayerItem(from: .init(url: videoURL, metadata: metadata), completionHandler: { [weak self] playerItem in
        guard let self = self else { return }
        self.playerItem = playerItem
        
        if sharedConfig.shouldAutoPlay {
          self.player?.play()
        } else {
          self.player?.pause()
        }
        
        if startTime != .zero {
          self.player?.seek(to: CMTime(seconds: startTime, preferredTimescale: 1))
        }

        connectPlayerLayer()
        addPeriodicTimeObserver()
        setNeedsLayout()
        layoutIfNeeded()
      })
    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(connectPlayerLayer), name: UIApplication.willEnterForegroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(disconnectPlayerLayer), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }
  
  open func onPlay() {
    guard let player else { return }
    player.play()
    isPlaying = true
  }
  
  open func onPause() {
    guard let player else { return }
    player.pause()
    isPlaying = false
  }
  
  fileprivate var playbackState: PlaybackState = .stopped {
    didSet {
      if oldValue != playbackState {
        delegate?.mediaPlayer(self, didChangePlaybackState: playbackState)
      }
    }
  }
  
  open func release() {
    DispatchQueue.main.async {
      if let timeObserver = self.timeObserver {
        self.player?.removeTimeObserver(timeObserver)
      }
      self.timeObserver = nil
      self.disconnectPlayerLayer()
      self.player?.replaceCurrentItem(with: nil)
      self.delegate = nil
    }
  }
  
  @objc fileprivate func connectPlayerLayer() {
    if let playerLayer {
      playerLayer.removeFromSuperlayer()
    }
    
    if let player {
      playerLayer = AVPlayerLayer(player: player)
      layer.addSublayer(playerLayer!)
    }
  }
  
  @objc fileprivate func disconnectPlayerLayer() {
    playerLayer?.removeFromSuperlayer()
    playerLayer = nil
  }
  
  fileprivate func onPlayerItemDidChange() {
    if lastPlayerItem == player?.currentItem {
      return
    }

    if let item = playerItem {
      NotificationCenter.default.addObserver(self, selector: #selector(mediaDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: item)
      addPlayerItemObservers(for: item)
    }
    
    lastPlayerItem = playerItem
  }
  
  fileprivate func addPlayerItemObservers(for item: AVPlayerItem) {
      item.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
  }
  
  fileprivate func removePlayerItemObservers(for item: AVPlayerItem) {
      item.removeObserver(self, forKeyPath: "status")
  }
  
  fileprivate func addPeriodicTimeObserver() {
    timeObserver = player?.addPeriodicTimeObserver(
          forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1),
          queue: .main
      ) { time in
          let seconds = time.seconds
          if seconds.isNaN || seconds.isInfinite {
              return
          }
        let availableTimeRanges = self.getAvailableTimeRanges()
        self.delegate?.mediaPlayer(self, didChangePlaybackTime: TimeInterval(time.seconds), loadedTimeRanges: availableTimeRanges!)
      }
  }
  
  open func removePeriodicTimeObserver() {
    player?.removeTimeObserver(timeObserver!)
  }
  
  @objc fileprivate func mediaDidFinishPlaying() {
    if playbackState != .ended {
      if let playerItem = playerItem {
        delegate?.mediaPlayer(self, duration: CMTimeGetSeconds(playerItem.duration))
      }
      
      self.playbackState = .ended
      self.isPlaying = false
      sharedConfig.log("Media Player has finished playing.")
    }
  }
  
  fileprivate func configureAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playback, mode: .default, options: [])
      try audioSession.setActive(true)
      sharedConfig.log("Audio session configured successfully.")
    } catch let error as NSError {
      let errorInfo: [String: Any] = [
        NSLocalizedDescriptionKey: "Failed to configure the audio session.",
        NSLocalizedFailureReasonErrorKey: "An error occurred while setting up the audio session.",
        NSLocalizedRecoverySuggestionErrorKey: "Check the audio session configuration or ensure no conflicts exist.",
        NSUnderlyingErrorKey: error
      ]
      let detailedError = NSError(domain: "\(String(describing: assetURL))", code: error.code, userInfo: errorInfo)
      //        NotificationCenter.default.post(name: .EventError, object: detailedError)
    }
  }
  
  fileprivate func getAvailableTimeRanges() -> TimeInterval? {
    if let loadTimeRanges = player?.currentItem?.loadedTimeRanges ,let firstRange = loadTimeRanges.first {
        let timeRange = firstRange.timeRangeValue
        let startTime = timeRange.start.seconds
        let durationTime = timeRange.duration.seconds
        let endTime = startTime + durationTime
        return endTime
      }
    return nil
  }
  
  open override func layoutSubviews() {
    self.playerLayer?.frame = self.bounds
  }
  
  override open func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey : Any]?,
    context: UnsafeMutableRawPointer?)
  {
    if keyPath == #keyPath(AVPlayer.status) {
      if let playerItem = playerItem {
        switch playerItem.status {
        case .readyToPlay:
          self.playbackState = .playing
          self.isPlaying = true
        case .unknown:
          self.playbackState = .stopped
        case .failed:
          self.delegate?.mediaPlayer(self, didFailWithError: playerItem.error)
          self.playbackState = .error
        @unknown default: break
        }
      }
    }
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    configureAudioSession()
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
