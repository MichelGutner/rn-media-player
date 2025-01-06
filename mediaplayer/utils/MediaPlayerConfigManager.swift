//
//  MediaPlayerManager.swift
//  Pods
//
//  Created by Michel Gutner on 02/01/25.
//
import AVFoundation
import Foundation
import AVKit

public let rctConfigManager = MediaPlayerConfigManager.shared

fileprivate let playbackSpeeds: NSDictionary = [
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
        rctConfigManager.log("Auto play enabled")
      } else {
        rctConfigManager.log("Auto play disabled")
      }
    }
  }
  
  open var menus: NSDictionary? = playbackSpeeds {
    didSet {
      if menus != oldValue {
        rctConfigManager.log("New menu items has been set")
      }
    }
  }

  open var allowLogs: Bool = false
  
  internal static func asset(from resource: MediaPlayerResourceDefinition) -> AVURLAsset {
    return AVURLAsset(url: resource.url, options: resource.options)
  }
  
  internal static func buildPlayerItem(from resource: MediaPlayerResource, completionHandler: @escaping (_ playerItem: AVPlayerItem) -> Void) {
    let asset = resource.definitions[0].avURLAsset
    let metadataItems = resource.metadataItems
    let item = AVPlayerItem(asset: asset)
    item.externalMetadata = metadataItems

    completionHandler(item)
  }
  
  func log(_ info:String) {
      if allowLogs {
          print(info)
      }
  }
}

