//
//  forwardButton.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 08/12/23.
//

import Foundation
import AVKit

class videoTimerManager {
  private weak var _player: AVPlayer?
  
  init(avPlayer: AVPlayer?) {
    _player = avPlayer
  }
  
  public func getCurrentTimeInSeconds() -> Float64 {
    let currentTime = _player?.currentTime()
    return CMTimeGetSeconds(currentTime!)
  }
  
  public func getDurationTimeInSeconds() -> Float64 {
    let duration = _player?.currentItem?.duration
    return CMTimeGetSeconds(duration!)
  }
  
  public func change(timeToChange: Double) {
    guard let currentTime = _player?.currentTime() else { return }
    let seekTimeSec = CMTimeGetSeconds(currentTime).advanced(by: timeToChange)
    let seekTime = CMTime(value: CMTimeValue(seekTimeSec), timescale: 1)
    _player?.seek(to: seekTime, completionHandler: {completed in})
  }
  
  public func advance(_ time: Double) {
    let videoTimer = videoTimerManager(avPlayer: _player!)
    videoTimer.change(timeToChange: time)
  }
}
