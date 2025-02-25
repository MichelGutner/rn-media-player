//
//  MediaPlayerManager.swift
//  Pods
//
//  Created by Michel Gutner on 02/01/25.
//
import AVFoundation
import Foundation
import AVKit

open class MediaPlayerConfigManager {
  public static let shared = MediaPlayerConfigManager()
  
  open var shouldAutoPlay: Bool = false {
    didSet {
      if shouldAutoPlay {
        Debug.log("Auto play enabled")
      } else {
        Debug.log("Auto play disabled")
      }
    }
  }

  open var thumbnails: NSDictionary? = nil {
    didSet {
      if thumbnails != oldValue {
        Debug.log("Thumbnails has been set")
      }
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

class Debug {
  static var isEnabled: Bool = false
  
  static func log(_ info: Any) {
    if (!isEnabled) { return }
    print("Log MediaPlayer : \(info)")
  }
  
  static func warning(_ info: Any) {
    if (!isEnabled) { return }
    print("Warning MediaPlayer : \(info)")
  }
}
