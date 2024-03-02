//
//  PlaybackObservable.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 12/02/24.
//

import Foundation
import AVFoundation

@available(iOS 13.0, *)
class PlayerObserver: ObservableObject {
  @Published var isFinishedPlaying = false
  @Published var playbackDuration = 0.0
  @Published var playbackCurrentTime = 0.0
  @Published var status = AVPlayerItem.Status.unknown
  @Published var thumbnailsFrames: [UIImage] = []
  @Published var isFullScreen: Bool = false
  
  @objc func itemDidFinishPlaying(_ notification: Notification) {
    isFinishedPlaying = true
  }
  
  @objc func playbackItem(_ notification: Notification) {
    guard let item = notification.object as? AVPlayerItem else { return }
    playbackDuration = item.duration.seconds
    playbackCurrentTime = item.currentTime().seconds
    status = item.status
  }
  
  @objc func generatedThumbnailFrames(_ notification: Notification) {
    thumbnailsFrames = (notification.userInfo?["frames"] as? [UIImage])!
  }
  @objc func onFullScreen(_ notification: Notification) {
    isFullScreen = (notification.userInfo?["fullScreen"] as? Bool)!
  }
}
