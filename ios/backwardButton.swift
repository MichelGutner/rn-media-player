//
//  backward.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 08/12/23.
//

import Foundation
import AVKit

class Backward {
  private weak var _player: AVPlayer?
  private var _time: Double
  init(player: AVPlayer?, time: Double) {
    _player = player
    _time = time
  }
  
  public func button() {
    let videoTimer = videoTimerManager(avPlayer: _player!)
    videoTimer.change(timeToChange: -_time)
  }
}
