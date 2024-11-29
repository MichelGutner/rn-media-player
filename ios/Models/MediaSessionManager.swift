//
//  MediaSessionManager.swift
//  Pods
//
//  Created by Michel Gutner on 25/11/24.
//


import SwiftUI
import AVKit
import AVFoundation
import Foundation
import Combine
import MediaPlayer

class MediaSessionManager: ObservableObject {
  @Published var player: AVPlayer? = nil
  @Published var isControlsVisible: Bool = false
  @Published var timeoutWorkItem: DispatchWorkItem?
  
  @Published var timeObserver: Any? = nil
  
  @Published var isFullscreen: Bool = false
  @Published var thumbnailsDictionary: NSDictionary? = nil
  @Published var newRate: Float = 1.0
  @Published var isPlaying: Bool = false
  @Published var isBuffering: Bool = true
  @Published var isReady: Bool = false
  
  @Published var isSeeking: Bool = false
  @Published var isFinished: Bool = false
  @Published var currentItemtitle: String? = nil
  
  @Published var missingDuration: Double = 0.0
  @Published var currentTime: Double = 0.0
  
  @Published var tapToSeek: (seekValue: Int, suffixSeekValue: String)? = nil
  
  private var cancellables: Set<AnyCancellable> = []
  
  init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleFinishAVPlayerItem),
      name: AVPlayerItem.didPlayToEndTimeNotification,
      object: nil
    )
  }
  
  deinit {}
  
  @objc private func handleFinishAVPlayerItem(_ notification: Notification) {
    guard let _ = notification.object as? AVPlayerItem else { return }
    MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0
    self.isFinished = true
  }
  
  func urlOfCurrentPlayerItem() -> URL? {
    return ((player?.currentItem?.asset) as? AVURLAsset)?.url
  }
  
  func makeNowPlayingInfo() {
    guard let player else { return }
    guard let currentItem = player.currentItem else { return }
    let metadata = currentItem.externalMetadata
    
    currentItemtitle = metadata.first { $0.identifier == .commonIdentifierTitle }?.stringValue ?? nil
    let artist = metadata.first { $0.identifier == .commonIdentifierArtist }?.stringValue ?? "Desconhecido"
    
    let nowPlayingInfo: [String: Any] = [
      MPMediaItemPropertyTitle: currentItemtitle ?? "Sem Título",
      MPMediaItemPropertyArtist: artist,
      MPMediaItemPropertyPlaybackDuration: currentItem.duration.seconds,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
      MPNowPlayingInfoPropertyPlaybackRate: player.rate
    ]
    
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
  
  func updateNowPlayingInfo(time: Double) {
    guard let player = player else { return }
    guard let currentItem = player.currentItem else { return }
    
    let duration = CMTimeGetSeconds(currentItem.duration)
    
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
  
  func setupRemoteCommandCenter() {
    guard let player else { return }
    let commandCenter = MPRemoteCommandCenter.shared()
    
    
    commandCenter.playCommand.addTarget { _ in
      player.play()
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1
      return .success
    }
    
    commandCenter.pauseCommand.addTarget { _ in
      player.pause()
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0
      
      return .success
    }
    
    commandCenter.changePlaybackPositionCommand.addTarget { event in
      guard let currentItem = player.currentItem else {
        return .commandFailed
      }
      
      let event = event as! MPChangePlaybackPositionCommandEvent
      let timestamp = event.positionTime
      let duration = currentItem.duration.seconds
      
      guard duration.isFinite, duration > 0 else { return .commandFailed }
      
      let playbackProgress = max(min(timestamp / duration, 1), 0)
      
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackProgress] = playbackProgress
      
      let targetTime = CMTime(seconds: timestamp, preferredTimescale: 600)
      
      player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
      
      return .success
    }
    
//    // Seek Forward Command
//    commandCenter.seekForwardCommand.addTarget { [weak self] _ in
//        guard let self = self else { return .commandFailed }
//        self.onForwardTime(10) // TODO: must be implemented from bridge
//        return .success
//    }
//    
//    // Seek Backward Command
//    commandCenter.seekBackwardCommand.addTarget { [weak self] event in
//      event.command.isEnabled = true
//        guard let self = self else { return .commandFailed }
//        self.onBackwardTime(10) // TODO: must be implemented from bridge
//        return .success
//    }
//    
//    // Enable/Disable Commands
//    commandCenter.seekForwardCommand.isEnabled = true
//    commandCenter.seekBackwardCommand.isEnabled = true
    
    commandCenter.nextTrackCommand.isEnabled = false

    commandCenter.skipForwardCommand.isEnabled = false
    commandCenter.skipBackwardCommand.isEnabled = false
  }
  
  func toggleControls() {
    withAnimation(.easeInOut(duration: 0.4), {
      isControlsVisible.toggle()
    })
  }
  
  func scheduleHideControls() {
    DispatchQueue.main.async { [self] in
      if let timeoutWorkItem {
        timeoutWorkItem.cancel()
      }
      
      if (isPlaying) {
        self.timeoutWorkItem = .init(block: { [self] in
          withAnimation(.easeInOut(duration: 0.4), {
            isControlsVisible = false
          })
        })
        
        
        if let timeoutWorkItem {
          DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: timeoutWorkItem)
        }
      }
    }
  }
  
  func cancelTimeoutWorkItem() {
    DispatchQueue.main.async { [self] in
      if let timeoutWorkItem {
        timeoutWorkItem.cancel()
      }
    }
  }
  
  func onBackwardTime(_ timeToChange: Int) {
    guard let player else { return }
    guard let currentItem = player.currentItem else { return }
    cancelTimeoutWorkItem()
    let currentTime = CMTimeGetSeconds(player.currentTime())
    let newTime = max(currentTime - Double(timeToChange), 0)
    
    if (newTime < currentItem.duration.seconds) {
      isFinished = false
    }
    
    player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                toleranceBefore: .zero,
                toleranceAfter: .zero,
                completionHandler: { _ in })
  }
  
  func onForwardTime(_ timeToChange: Int) {
    guard let player else { return }
    guard let currentItem = player.currentItem else { return }
    cancelTimeoutWorkItem()
    
    let currentTime = CMTimeGetSeconds(player.currentTime())
    let newTime = max(currentTime + Double(timeToChange), 0)
    
    if (newTime < currentItem.duration.seconds) {
      isFinished = false
    }
    
    player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                toleranceBefore: .zero,
                toleranceAfter: .zero,
                completionHandler: { _ in })
  }
  
  func setupPlayerObservation() {
    guard let player else { return }
    guard let currentItem = player.currentItem else { return }
    player.publisher(for: \.timeControlStatus)
      .sink { [self] status in
        isPlaying = (status == .playing)
        isBuffering = (status == .waitingToPlayAtSpecifiedRate)
      }
      .store(in: &cancellables)
    
    player.currentItem?.publisher(for: \.status)
        .sink { status in
          switch status {
          case .readyToPlay:
            self.isReady = true
            NotificationCenter.default.post(
              name: .EventReady,
              object: nil,
              userInfo: [
                "ready": true,
                "duration": currentItem.duration.seconds
              ]
            )
          case .failed:
            NotificationCenter.default.post(name: .EventError, object: currentItem.error)
          case .unknown:
            break
          @unknown default:
            break
          }
        }
        .store(in: &cancellables)
    
    currentItem.publisher(for: \.isPlaybackBufferFull)
      .sink { isFull in
        NotificationCenter.default.post(name: .EventBuffer, object: nil, userInfo: ["completed": isFull])
      }
      .store(in: &cancellables)
    
    currentItem.publisher(for: \.isPlaybackLikelyToKeepUp)
      .sink { isBuffering in
        NotificationCenter.default.post(name: .EventBuffer, object: nil, userInfo: ["buffering": !isBuffering])
      }
      .store(in: &cancellables)
    
    currentItem.publisher(for: \.isPlaybackBufferEmpty)
      .sink { isEmpty in
        NotificationCenter.default.post(name: .EventBuffer, object: nil, userInfo: ["empty": isEmpty])
      }
      .store(in: &cancellables)
  }
  
  func clear() {
    thumbnailsDictionary = [:]
    cancellables.removeAll()
  }
  
  
}
