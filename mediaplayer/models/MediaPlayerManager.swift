//
//  MediaPlayerManager.swift
//  rn-media-player
//
//  Created by Michel Gutner on 06/01/25.
//

import Foundation
import UIKit
import AVFoundation
import SwiftUI
import Combine


public class Shared {
    public static let instance = Shared()
    public var source: PlayerSource?
  
    internal static func setInstance(_ source: PlayerSource?) {
    instance.source = source
  }
}

public protocol PlayerSourceViewDelegate : AnyObject {
  func mediaPlayer(_ player: PlayerSource, didFinishPlayingWithError error: Error?)
  func mediaPlayer(_ player: PlayerSource, didChangePlaybackState state: PlaybackState)
  func mediaPlayer(_ player: PlayerSource, duration: TimeInterval)
  func mediaPlayer(_ player: PlayerSource, mediaDidChangePlaybackRate rate: Float)
  func mediaPlayer(_ player: PlayerSource, mediaIsPlayingDidChange isPlaying: Bool)
  func mediaPlayer(_ player: PlayerSource, didChangeReadyToDisplay isReadyToDisplay: Bool)
  func mediaPlayer(_ player: PlayerSource, didFailWithError error: (any Error)?)
}


open class PlayerSource: UIView {
  fileprivate var startTime: Double = 0.0
  fileprivate var lastPlayerItem: AVPlayerItem?
  fileprivate var playerLayerManager: MediaPlayerLayerManager? = MediaPlayerLayerManager()
  fileprivate let audioManager = MediaPlayerAudioManager()
  
  open weak var delegate: PlayerSourceViewDelegate?
  
  open var playerItem: AVPlayerItem? {
    didSet {
      onPlayerItemDidChange()
    }
  }
  
  open var playerLayer: AVPlayerLayer? {
    playerLayerManager?.activeLayer
  }
  
  open weak var player: AVPlayer?
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    Shared.setInstance(self)
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open var assetURL: URL? {
    guard let player else { return nil }
    return (player.currentItem?.asset as? AVURLAsset)?.url
  }
  
  open var isPlaying: Bool = false {
    didSet {
      if oldValue != isPlaying {
        delegate?.mediaPlayer(self, mediaIsPlayingDidChange: isPlaying)
      }
    }
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
  
  open var playbackState: PlaybackState = .waiting {
    didSet {
      if oldValue != playbackState {
        delegate?.mediaPlayer(self, didChangePlaybackState: playbackState)
      }
    }
  }
  
  open var isReady: Bool = false {
    didSet {
      if oldValue != isReady {
        delegate?.mediaPlayer(self, didChangeReadyToDisplay: isReady)
      }
    }
  }
  
  fileprivate func onPlayerItemDidChange() {
    if lastPlayerItem == playerItem {
      return
    }
    
    didConnectPlayerLayer()
    
    if let item = playerItem {
      NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: item)
      addPlayerItemObservers(for: item)
    }
    
    lastPlayerItem = playerItem
    
    NotificationCenter.default.addObserver(self, selector: #selector(didConnectPlayerLayer), name: UIApplication.willEnterForegroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(didDisconnectPlayerLayer), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }
  
  @objc fileprivate func playerDidFinishPlaying() {
    if playbackState != .ended {
      if let playerItem = playerItem {
        delegate?.mediaPlayer(self, duration: CMTimeGetSeconds(playerItem.duration))
      }
      
      self.playbackState = .ended
      self.isPlaying = false
      appConfig.log("Media Player has finished playing.")
    }
  }
  
  @objc fileprivate func didConnectPlayerLayer() {
    guard let player = player else {
      return
    }
    playerLayerManager?.attachPlayer(with: player) { [weak self] playerLayer in
      guard let self = self else { return }
      playerLayer.frame = self.bounds
      self.layer.addSublayer(playerLayer)
    }
    
    setNeedsLayout()
    layoutIfNeeded()
  }
  
  @objc fileprivate func didDisconnectPlayerLayer() {
    playerLayerManager?.detachCurrentLayer()
  }
  
  internal func setup(with source: NSDictionary?) {
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
    
    // Atribui a referência forte à propriedade weak
    self.player = strongPlayer
    
    self.playerItem = newPlayerItem
    self.startTime = startTime
    self.playbackState = .waiting
    
    audioManager.activateAudioSession { isSuccess, error in
      if isSuccess {
        appConfig.log("Audio session activated successfully.")
      } else {
        appConfig.log("Failed to activate audio session: \(error)")
      }
    }
  }
  
  public func cleanup() {
      NotificationCenter.default.removeObserver(self)
      
      didDisconnectPlayerLayer()
      
      if let playerItem = lastPlayerItem {
          NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
          removePlayerItemObservers(for: playerItem)
      }
      
      player?.pause()
      player?.replaceCurrentItem(with: nil)
      player = nil
      lastPlayerItem = nil
      
      
      audioManager.deactivateAudioSession { isSuccess, error in
          if isSuccess {
              print("Audio session deactivated successfully.")
          } else {
              print("Failed to deactivate audio session: \(error)")
          }
      }
      
      isPlaying = false
      playbackState = .waiting
      isReady = false
  }
  
  open override func layoutSubviews() {
    super.layoutSubviews()
    playerLayerManager?.setLayerFrame(to: bounds)
  }
}

extension PlayerSource {
  fileprivate func addPlayerItemObservers(for item: AVPlayerItem) {
    item.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
  }
  
  fileprivate func removePlayerItemObservers(for item: AVPlayerItem) {
    item.removeObserver(self, forKeyPath: "status")
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
          if appConfig.shouldAutoPlay {
            player?.play()
            playbackState = .playing
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isReady = true
          }
          break
        case .unknown:
          self.playbackState = .waiting
        case .failed:
          self.delegate?.mediaPlayer(self, didFailWithError: playerItem.error)
          self.playbackState = .error
        @unknown default: break
        }
      }
    }
  }
}

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

open class MediaPlayerLayerManager {
  fileprivate var activeLayer: AVPlayerLayer?
  
  open func attachPlayer(with player: AVPlayer, onAttached: @escaping (AVPlayerLayer) -> Void) {
    detachCurrentLayer()
    
    let newPlayerLayer = AVPlayerLayer(player: player)
    newPlayerLayer.name = UUID().uuidString
    appConfig.log("Connected player layer with id \(newPlayerLayer.name ?? "unknown")")
    activeLayer = newPlayerLayer
    onAttached(newPlayerLayer)
  }
  
  open func detachCurrentLayer() {
      if let name = activeLayer?.name {
          appConfig.log("Desconnected player layer with id \(name)")
      } else {
          appConfig.log("No active player layer to detach")
      }
      activeLayer?.removeFromSuperlayer()
      activeLayer = nil
  }
  
  open func setLayerFrame(to frame: CGRect) {
    activeLayer?.frame = frame
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
