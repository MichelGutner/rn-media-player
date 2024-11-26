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
  @Published var isControlsVisible: Bool = true
  @Published var timeoutWorkItem: DispatchWorkItem?
  
  @Published var timeObserver: Any? = nil
  
  @Published var isFullscreen: Bool = false
  @Published var thumbnailsDictionary: NSDictionary? = nil
  @Published var newRate: Float = 1.0
  @Published var isPlaying: Bool = false
  
  @Published var isSeeking: Bool = false
  @Published var isFinished: Bool = false
  @Published var currentItemtitle: String? = nil
  
  @Published var missingDuration: Double = 0.0
  @Published var currentTime: Double = 0.0
  
  init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleFinishAVPlayerItem),
      name: AVPlayerItem.didPlayToEndTimeNotification,
      object: nil
    )
  }
  
  
  
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
    player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                toleranceBefore: .zero,
                toleranceAfter: .zero,
                completionHandler: { _ in })
  }
  
  func clear() {
    thumbnailsDictionary = [:]
  }
  
  
}
