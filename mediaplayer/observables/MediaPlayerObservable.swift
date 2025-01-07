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
  @Published public var duration: Double = 0.0
  @Published public var isReadyToDisplay: Bool = false
  
  func updateIsPlaying(to value: Bool) {
    isPlaying = value
  }
  
  func updateIsFullScreen(to value: Bool) {
    isFullScreen = value
  }

  func updateIsReadyToDisplay(to value: Bool) {
    isReadyToDisplay = value
  }
}
