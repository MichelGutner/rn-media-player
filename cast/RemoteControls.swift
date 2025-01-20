//
//  RemoteControls.swift
//  Pods
//
//  Created by Michel Gutner on 19/01/25.
//

import AVFoundation
import MediaPlayer

public enum RemoteControlCommand {
  case play
  case pause
  case skipForward
  case skipBackward
}

public protocol RemoteControlsDelegate: AnyObject {
  func remoteControls(_ remoteControls: RemoteControls, didReceive command: RemoteControlCommand)
}

open class RemoteControls {
  fileprivate var player: AVPlayer?
  open weak var delegate: RemoteControlsDelegate?
  fileprivate var nowPlayingInfo: [String : Any]? = [:]
  
  public init(player: AVPlayer?) {
    self.player = player
  }
  
  required public init() {}
  
  open func setPlaybackTimes(currentTime: Double, duration: Double) {
    nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration
    nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  open func makeNowPlayingInfo() {
    guard let currentItem = player?.currentItem else { return }
    let metadata = currentItem.externalMetadata
    
    let title = metadata.first { $0.identifier == .commonIdentifierTitle }?.stringValue ?? ""
    let artist = metadata.first { $0.identifier == .commonIdentifierArtist }?.stringValue ?? ""
    
    self.nowPlayingInfo?[MPMediaItemPropertyTitle] = title
    self.nowPlayingInfo?[MPMediaItemPropertyArtist] = artist
    self.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate ?? 0.0
    
    setupRemoteCommandCenter()
  }
  
  fileprivate func setupRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()
    
    commandCenter.playCommand.addTarget { _ in
      self.delegate?.remoteControls(self, didReceive: .play)
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1
      
      return .success
    }
    
    commandCenter.pauseCommand.addTarget { _ in
      self.delegate?.remoteControls(self, didReceive: .pause)
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0
      
      return .success
    }
    
    commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let self = self else { return .commandFailed }
      guard let currentItem = player?.currentItem else {
        return .commandFailed
      }
      
      let event = event as! MPChangePlaybackPositionCommandEvent
      let timestamp = event.positionTime
      let duration = currentItem.duration.seconds
      
      guard duration.isFinite, duration > 0 else { return .commandFailed }
      
      let playbackProgress = max(min(timestamp / duration, 1), 0)
      
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackProgress] = playbackProgress
      
      let targetTime = CMTime(seconds: timestamp, preferredTimescale: 600)
      
      player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
      
      return .success
    }
    
    commandCenter.skipBackwardCommand.addTarget { [weak self] event in
      guard let self = self, let player, let currentItem = player.currentItem else {
        return .commandFailed
      }
      
      guard let duration = currentItem.duration.seconds.isFinite ? currentItem.duration.seconds : nil else {
        return .commandFailed
      }
      
      let newTimestamp = player.currentTime().seconds - 10
      let clampedTimestamp = max(newTimestamp, 0)
      
      let playbackProgress = clampedTimestamp / duration
      
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackProgress] = playbackProgress
      
      let targetTime = CMTime(seconds: clampedTimestamp, preferredTimescale: 600)
      player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
      
      self.delegate?.remoteControls(self, didReceive: .skipBackward)
      return .success
    }
    
    commandCenter.skipForwardCommand.addTarget { [weak self] event in
      guard let self = self, let player, let currentItem = player.currentItem else {
        return .commandFailed
      }
      
      guard let duration = currentItem.duration.seconds.isFinite ? currentItem.duration.seconds : nil else {
        return .commandFailed
      }
      
      let newTimestamp = player.currentTime().seconds + 10
      let clampedTimestamp = max(newTimestamp, 0)
      
      let playbackProgress = clampedTimestamp / duration
      
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackProgress] = playbackProgress
      
      let targetTime = CMTime(seconds: clampedTimestamp, preferredTimescale: 600)
      player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
      
      self.delegate?.remoteControls(self, didReceive: .skipForward)
      return .success
    }
  }
}
