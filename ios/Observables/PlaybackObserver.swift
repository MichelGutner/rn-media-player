//
//  PlaybackObserver.swift
//  Pods
//
//  Created by Michel Gutner on 03/10/24.
//

import SwiftUI
import AVKit

class PlaybackObservable: NSObject, ObservableObject {
  @Published var player: AVPlayer? = nil
  @Published var timeControlStatus: AVPlayer.TimeControlStatus = .waitingToPlayAtSpecifiedRate
  @Published var isBuffering: Bool = false
  @Published var playerItemStatus: AVPlayerItem.Status = .unknown
  @Published var duration: Double = 0.0
  @Published var loadedTimeRanges: [NSValue] = []
  
  override init() {
    super.init()
    
    NotificationCenter.default.addObserver(self, selector: #selector(handlePlayerItem(_:)), name: .PlayerItem, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleTimeoutControlStatus(_:)), name: .AVPlayerTimeControlStatus, object: nil)
  }
  
  @objc private func handlePlayerItem(_ notification: Notification) {
    guard let playerItem = notification.object as? AVPlayerItem else { return }
    isBuffering = !playerItem.isPlaybackLikelyToKeepUp
    playerItemStatus = playerItem.status
    duration = playerItem.duration.seconds
    loadedTimeRanges = playerItem.loadedTimeRanges
  }
  
  @objc private func handleTimeoutControlStatus(_ notification: Notification) {
    guard let status = notification.object as? AVPlayer.TimeControlStatus else { return }
    self.timeControlStatus = status
  }
}
