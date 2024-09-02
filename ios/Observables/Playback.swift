//
//  PlaybackObservable.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 12/02/24.
//

import Foundation
import AVFoundation

class PlaybackObserver: ObservableObject {
  @Published var isFinishedPlaying = false
  @Published var playbackDuration = 0.0
  @Published var playbackCurrentTime = 0.0
  @Published var status = AVPlayerItem.Status.unknown
  @Published var thumbnailsFrames: [UIImage] = []
  @Published var currentTime: Double = 0.0
  
  @objc func itemDidFinishPlaying(_ notification: Notification) {
    isFinishedPlaying = true
  }
  
  @objc func playbackItem(_ notification: Notification) {
    guard let item = notification.object as? AVPlayerItem else { return }
    
    playbackDuration = item.duration.seconds
    playbackCurrentTime = item.currentTime().seconds
    status = item.status
  }
  
  @objc func periodTimeObserver(_ notification: Notification) {
    currentTime = notification.userInfo?["currentTime"] as! Double
  }
  
  @objc func getThumbnailFrames(_ notification: Notification) {
    thumbnailsFrames = (notification.userInfo?["frames"] as? [UIImage])!
  }
}


public func notificationPostModal(userInfo: [String: Any]) {
  NotificationCenter.default.post(name: Notification.Name("modal"), object: nil, userInfo: userInfo)
}

public func notificationPostPlaybackInfo(userInfo: [String: Any]) {
  NotificationCenter.default.post(name: Notification.Name("playbackInfo"), object: nil, userInfo: userInfo)
}
