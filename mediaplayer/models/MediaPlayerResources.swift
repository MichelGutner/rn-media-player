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
    let metadata = MediaPlayerItemMetadata(metadata: metadata)
    
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
  
  open var avURLAsset: AVURLAsset {
    get {
      guard !url.isFileURL, url.pathExtension != "m3u8" else {
        return AVURLAsset(url: url)
      }
      
      return MediaPlayerConfigManager.asset(from: self)
    }
  }
  
  public init(url: URL, definition: String? = "", options: [String : Any]? = nil) {
    self.url = url
    self.definition = definition
    self.options = options
  }
}

open class MediaPlayerItemMetadata {
  private let metadataIdentifier: AVMetadataIdentifier? = nil
  private var metadata: NSDictionary
  open var items: [AVMetadataItem] = []
  
  init(metadata: NSDictionary?) {
    self.metadata = metadata ?? [:]
    processMetadata()
  }
  
  fileprivate func processMetadata() {
    for (key, value) in metadata {
      guard let keyString = key as? String,
            let valueString = value as? String else {
        continue
      }
      
      guard let identifier = mapKeyToMetadataIdentifier(keyString) else {
        continue
      }
      
      let metadataItem = AVMutableMetadataItem()
      metadataItem.identifier = identifier
      metadataItem.value = valueString as NSString
      metadataItem.locale = Locale.current
      
      items.append(metadataItem)
    }
  }
  
  fileprivate func mapKeyToMetadataIdentifier(_ key: String) -> AVMetadataIdentifier? {
    switch key {
    case "title":
      return .commonIdentifierTitle
    case "artist":
      return .commonIdentifierArtist
    case "albumName":
      return .commonIdentifierAlbumName
    default:
      return nil
    }
  }
}

