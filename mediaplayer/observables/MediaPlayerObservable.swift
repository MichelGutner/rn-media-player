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

public protocol MediaPlayerObservableObjectProtocol: AnyObject {
    var sliderProgress: CGFloat { get set }
    var bufferingProgress: CGFloat { get set }
    var isPlaying: Bool { get set }
    var isFullScreen: Bool { get set }
}

public class MediaPlayerObservable: ObservableObject, MediaPlayerObservableObjectProtocol {
  @Published public var isPlaying: Bool = false
  @Published public var isFullScreen: Bool = false
  @Published public var bufferingProgress: CGFloat = 0.0
  @Published public var sliderProgress: CGFloat = 0.0
  
  func updateSeekBar(sliderProgressValue sValue: CGFloat, bufferingProgressValue bValue: CGFloat) {
    sliderProgress = sValue
    bufferingProgress = bValue
  }
  
  // TODO: need remove
  func updateBufferingProgress(to value: CGFloat) {
    bufferingProgress = value
  }
  
  func updateIsPlaying(to value: Bool) {
    isPlaying = value
  }
  
  func updateIsFullScreen(to value: Bool) {
    isFullScreen = value
  }
}
