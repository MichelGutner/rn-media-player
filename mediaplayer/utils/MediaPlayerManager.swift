//
//  MediaPlayerManager.swift
//  Pods
//
//  Created by Michel Gutner on 02/01/25.
//
import AVFoundation
import Foundation
import AVKit

public let sharedConfig = MediaPlayerManager.shared

open class MediaPlayerManager {
  public static let shared = MediaPlayerManager()
  
  open var shouldAutoPlay: Bool = false {
    didSet {
      if shouldAutoPlay {
        sharedConfig.log("Auto play enabled")
      } else {
        sharedConfig.log("Auto play disabled")
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

