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
 
  @objc func itemDidFinishPlaying(_ notification: Notification) {
    isFinishedPlaying = true
  }
  
  @objc func playbackItemDuration(_ notification: Notification) {
    guard let item = notification.object as? AVPlayerItem else { return }
    print("playback", playbackDuration)
    playbackDuration = item.duration.seconds
  }
}
