//
//  forwardButton.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 08/12/23.
//

import Foundation
import AVKit

class AdvanceTime {
  private weak var _player: AVPlayer?
  init(player: AVPlayer?) {
    _player = player
  }
  
  public func change(_ time: Double) {
    let videoTimer = videoTimerManager(avPlayer: _player!)
    videoTimer.change(timeToChange: time)
  }
}
