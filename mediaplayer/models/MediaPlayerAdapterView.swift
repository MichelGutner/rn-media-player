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

public protocol MediaPlayerAdapterViewDelegate : AnyObject {
  func mediaPlayer(_ player: MediaPlayerAdapterView, didFinishPlayingWithError error: Error?)
  func mediaPlayer(_ player: MediaPlayerAdapterView, didChangePlaybackState state: PlaybackState)
  func mediaPlayer(_ player: MediaPlayerAdapterView, duration: TimeInterval)
  func mediaPlayer(_ player: MediaPlayerAdapterView, didChangePlaybackTime currentTime: TimeInterval, loadedTimeRanges timeRanges: TimeInterval, diChangePlaybackDuration duration: TimeInterval)
  func mediaPlayer(_ player: MediaPlayerAdapterView, mediaDidChangePlaybackRate rate: Float)
  func mediaPlayer(_ player: MediaPlayerAdapterView, mediaIsPlayingDidChange isPlaying: Bool)
  func mediaPlayer(_ player: MediaPlayerAdapterView, didChangeReadyToDisplay isReadyToDisplay: Bool)
  func mediaPlayer(_ player: MediaPlayerAdapterView, didFailWithError error: (any Error)?)
}

open class MediaPlayerAdapterView : UIView {
  open weak var delegate: MediaPlayerAdapterViewDelegate?
  fileprivate var lastPlayerItem: AVPlayerItem?
  fileprivate var timeObserver: Any? = nil
  
  open var playerItem: AVPlayerItem? {
    didSet {
      onPlayerItemDidChange()
    }
  }
  
  open weak var playerLayer: AVPlayerLayer?
  
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
  
  open func setup(with source: NSDictionary?) {
    guard let urlString = source?["url"] as? String,
          let videoURL = URL(string: urlString) else {
      return
    }
    
    let startTime = source?["startTime"] as? Double ?? 0
    let metadata = source?["metadata"] as? NSDictionary
    
    NotificationCenter.default.addObserver(self, selector: #selector(connectPlayerLayer), name: UIApplication.willEnterForegroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(disconnectPlayerLayer), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }
  
  open func seekTo(with time: CMTime, completionHandler: @escaping (Bool) -> Void) {
    player?.seek(to: time, completionHandler: completionHandler)
  }
  
  open func onPlay() {
    guard let player else { return }
    player.play()
    isPlaying = true
    playbackState = .playing
  }
  
  open func onPause() {
    guard let player else { return }
    player.pause()
    isPlaying = false
    playbackState = .paused
  }
  
  open func onReplay() {
    guard let player else { return }
    player.seek(to: .zero)
    player.play()
    isPlaying = true
    playbackState = .playing
  }
  
  open var playbackState: PlaybackState = .stopped {
    didSet {
      if oldValue != playbackState {
        delegate?.mediaPlayer(self, didChangePlaybackState: playbackState)
      }
    }
  }
  
  open var isReadyToDisplay: Bool = false {
    didSet {
      if oldValue != isReadyToDisplay {
        delegate?.mediaPlayer(self, didChangeReadyToDisplay: isReadyToDisplay)
      }
    }
  }
  
  open func release() {
    DispatchQueue.main.async {
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
  
  @objc fileprivate func mediaDidFinishPlaying() {
    if playbackState != .ended {
      if let playerItem = playerItem {
        delegate?.mediaPlayer(self, duration: CMTimeGetSeconds(playerItem.duration))
      }
      
      self.playbackState = .ended
      self.isPlaying = false
      appConfig.log("Media Player has finished playing.")
    }
  }
  
  fileprivate func configureAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playback, mode: .default, options: [])
      try audioSession.setActive(true)
      appConfig.log("Audio session configured successfully.")
    } catch let error as NSError {
      let errorInfo: [String: Any] = [
        NSLocalizedDescriptionKey: "Failed to configure the audio session.",
        NSLocalizedFailureReasonErrorKey: "An error occurred while setting up the audio session.",
        NSLocalizedRecoverySuggestionErrorKey: "Check the audio session configuration or ensure no conflicts exist.",
        NSUnderlyingErrorKey: error
      ]
      let detailedError = NSError(domain: "\(String(describing: assetURL))", code: error.code, userInfo: errorInfo)
      //        NotificationCenter.default.post(name: .EventError, object: detailedError)
      self.delegate?.mediaPlayer(self, didFailWithError: detailedError)
    }
  }
  
  fileprivate func getAvailableTimeRanges() -> TimeInterval {
    if let loadTimeRanges = player?.currentItem?.loadedTimeRanges ,let firstRange = loadTimeRanges.first {
        let timeRange = firstRange.timeRangeValue
        let startTime = timeRange.start.seconds
        let durationTime = timeRange.duration.seconds
        let endTime = startTime + durationTime
        return endTime
      }
    return 0.0
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
          isReadyToDisplay = true
          break
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
