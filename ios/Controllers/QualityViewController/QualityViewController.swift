//
//  QualityManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 31/01/24.
//


import Foundation
import AVFoundation

/**
 @abstract   auto manager quality of videos using observe bit rate
 @abstract WIP - not working 100%.
 */
class QualityViewController {
  private var player: AVPlayer?
  private var playerItem: AVPlayerItem?
  
  private var lowBitrateURL: URL
  private var mediumBitrateURL: URL
  private var highBitrateURL: URL
  
  init(player: AVPlayer? = nil, playerItem: AVPlayerItem? = nil, lowBitrateURL: URL, mediumBitrateURL: URL, highBitrateURL: URL) {
    self.player = player
    self.playerItem = playerItem
    self.lowBitrateURL = lowBitrateURL
    self.mediumBitrateURL = mediumBitrateURL
    self.highBitrateURL = highBitrateURL
  }
  
  public func checkAccessLog() {
    if let accessLog = playerItem?.accessLog(), let event = accessLog.events.last {
      let observerBitrate = event.observedBitrate
      
      if observerBitrate < 500_000 {
        changeURL(newURL: lowBitrateURL)
      } else if observerBitrate < 1_000_000 {
        changeURL(newURL: mediumBitrateURL)
      } else {
        changeURL(newURL: highBitrateURL)
      }
    }
  }
  
  private func changeURL(newURL: URL) {
    if let currentItem = player?.currentItem {
      let newPlayerItem = AVPlayerItem(url: newURL)
      
      player?.replaceCurrentItem(with: newPlayerItem)
      
      currentItem.seek(to: .zero, completionHandler: nil)
    }
  }
  
}
