//
//  MediaPlayerManager.swift
//  Pods
//
//  Created by Michel Gutner on 02/01/25.
//
import AVFoundation
import Foundation
import AVKit

public let appConfig = MediaPlayerConfigManager.shared

fileprivate let defaultOptionsMenu: NSDictionary = [
  "Speeds": [
      "data": [
          ["name": "0.5x", "value": "0.5"],
          ["name": "Normal", "value": 1],
          ["name": "1.5x", "value": "1.5"],
          ["name": "2.0x", "value": 2]
      ],
      "initialItemSelected": "Normal"
  ]
]

open class MediaPlayerConfigManager {
  public static let shared = MediaPlayerConfigManager()
  
  open var shouldAutoPlay: Bool = false {
    didSet {
      if shouldAutoPlay {
        appConfig.log("Auto play enabled")
      } else {
        appConfig.log("Auto play disabled")
      }
    }
  }
  
  open var playbackMenu: NSDictionary? = defaultOptionsMenu {
    didSet {
      if playbackMenu != oldValue {
        appConfig.log("New menu items has been set")
      }
    }
  }
  
  open var thumbnails: NSDictionary? = nil {
    didSet {
      if thumbnails != oldValue {
        appConfig.log("Thumbnails has been set")
      }
    }
  }

  open var isLoggingEnabled: Bool = false
  
  func log( _ info: Any) {
      if isLoggingEnabled {
        print("RNMediaPlayer \(info)")
      }
  }
}

public class PlayerManager {
  public static let shared = PlayerManager()
  open weak var currentPlayer: AVPlayer?
  open var timeObserve: Any?
  
  internal static func updateInstance(player: AVPlayer?) {
    shared.currentPlayer = player
  }
}
