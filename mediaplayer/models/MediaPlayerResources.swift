//
//  MediaPlayerResources.swift
//  Pods
//
//  Created by Michel Gutner on 02/01/25.
//

import Foundation
import AVFoundation

public class MediaPlayerResource {
  public let definitions: [MediaPlayerResourceDefinition]
  public var metadataItems: [AVMetadataItem] = []
  
  public convenience init(url: URL, metadata: NSDictionary?) {
    let definition = MediaPlayerResourceDefinition(url: url, definition: "")
    let metadata = MediaPlayerItemMetadataManager(metadata: metadata)
    
    self.init(metadataItems: metadata.items, definitions: [definition])
  }
  
  public init(metadataItems: [AVMetadataItem] = [], definitions: [MediaPlayerResourceDefinition]) {
    self.metadataItems = metadataItems
    self.definitions = definitions
  }
}

open class MediaPlayerResourceDefinition {
  let url: URL
  let definition: String?
  
  public var options: [String: Any]?
  
//  open var avURLAsset: AVURLAsset {
//    get {
//      guard !url.isFileURL, url.pathExtension != "m3u8" else {
//        return AVURLAsset(url: url)
//      }
//      
////      return MediaPlayerConfigManager.asset(from: self)
//    }
//  }
  
  public init(url: URL, definition: String? = "", options: [String : Any]? = nil) {
    self.url = url
    self.definition = definition
    self.options = options
  }
}

