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
  private var _shapeLayer = CustomCAShapeLayers()
  
  init(avPlayer: AVPlayer?) {
    _player = avPlayer
  }
  
  public func change(timeToChange: Double) {
    let svgShapeLayer = _shapeLayer.createForwardShapeLayer(timeToChange as NSNumber)
    guard let currentTime = _player?.currentTime() else { return }
    let seekTimeSec = CMTimeGetSeconds(currentTime).advanced(by: timeToChange)
    let seekTime = CMTime(value: CMTimeValue(seekTimeSec), timescale: 1)
    _player?.seek(to: seekTime, completionHandler: {completed in})
  }
}