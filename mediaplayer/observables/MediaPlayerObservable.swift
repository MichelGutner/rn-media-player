//
//  MediaPlayerObservable.swift
//  Pods
//
//  Created by Michel Gutner on 05/01/25.
//

import AVKit
import UIKit
import AVFoundation
import SwiftUI

public class MediaPlayerObservable: ObservableObject {
  @Published public var isPlaying: Bool = false
  @Published public var isFullScreen: Bool = false
  @Published public var bufferingProgress: CGFloat = 0.0
  @Published public var sliderProgress: CGFloat = 0.0
  @Published public var currentTime: Double = 0.0
  @Published public var duration: Double = 0.0
  @Published public var isSeeking: Bool = false
  @Published public var isReadyToDisplay: Bool = false
  
  func updateSeekBar(sliderProgressValue sValue: CGFloat, bufferingProgressValue bValue: CGFloat) {
    if !isSeeking, sValue < duration, bValue > 0 {
      sliderProgress = sValue
      bufferingProgress = bValue
    }
  }
  
  func updateMediaTimeValues(currentTimeValue cValue: CGFloat, duration dValue: CGFloat) {
    if !isSeeking {
      currentTime = cValue
      duration = dValue
    }
  }
  
  func updateIsPlaying(to value: Bool) {
    isPlaying = value
  }
  
  func updateIsFullScreen(to value: Bool) {
    isFullScreen = value
  }
  
  func updateIsSeeking(to value: Bool) {
    isSeeking = value
  }
  
  func updateIsReadyToDisplay(to value: Bool) {
    isReadyToDisplay = value
  }
}
