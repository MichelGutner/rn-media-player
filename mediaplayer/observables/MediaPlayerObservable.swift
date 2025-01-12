//
//  MediaPlayerObservable.swift
//  Pods
//
//  Created by Michel Gutner on 05/01/25.
//

import Combine

open class PlaybackStateObservable: ObservableObject {
    public static let shared = PlaybackStateObservable()
    private init() {}
    
    @Published public var isPlaying: Bool = false
    @Published public var duration: Double = 0.0
    @Published public var isReady: Bool = false
    
    internal static func updateIsPlaying(to value: Bool) {
      PlaybackStateObservable.shared.isPlaying = value
    }
    
    internal static func updateDuration(to value: Double) {
      PlaybackStateObservable.shared.duration = value
    }
  
    internal static func setIsReadyForDisplay(to value: Bool) {
      PlaybackStateObservable.shared.isReady = value
    }
}

import Combine

public class ScreenStateObservable: ObservableObject {
    public static let shared = ScreenStateObservable()
    private init() {}
    @Published public var isFullScreen: Bool = false
    
    internal static func setFullscreenState(to value: Bool) {
      ScreenStateObservable.shared.isFullScreen = value
    }
}
