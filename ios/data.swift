//
//  SpeedRateData.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 30/01/24.
//

@available(iOS 13.0, *)
public var playbackSpeedData: [HashableItem] = [
  HashableItem(name: "0.5x", value: "0.5", enabled: true),
  HashableItem(name: "0.75x", value: "0.75", enabled: true),
  HashableItem(name: "Normal", value: "1", enabled: true),
  HashableItem(name: "1.25x", value: "1.25", enabled: true),
  HashableItem(name: "1.5x", value: "1.5", enabled: true),
  HashableItem(name: "2.0x", value: "2.0", enabled: true)
]

@available(iOS 13.0, *)
public var qualityOptionsData: [HashableItem] = [
    HashableItem(name: "144p", enabled: true),
    HashableItem(name: "240p", enabled: true),
    HashableItem(name: "360p", enabled: true),
    HashableItem(name: "480p", enabled: true),
    HashableItem(name: "720p", enabled: true),
    HashableItem(name: "1080p", enabled: true),
    HashableItem(name: "1440p", enabled: false),
    HashableItem(name: "2160p", enabled: false),
    HashableItem(name: "2880p", enabled: false),
    HashableItem(name: "4320p", enabled: false)
]


@available(iOS 13.0, *)
public var settingsData: [HashableItem] = [
  HashableItem(name: "Quality", value: "quality", enabled: true),
  HashableItem(name: "Playback speed", value: "playbackSpeed", enabled: true),
  HashableItem(name: "More Options", value: "moreOptions", enabled: true)
]


struct VideoQualityData : Hashable {
  let name: String
  let value: String
  let enabled: Bool
  
  init(name: String, value: String, enabled: Bool) {
    self.name = name
    self.value = value
    self.enabled = enabled
  }
  
  init(dictionary: [String: Any]) {
    self.name = dictionary["name"] as? String ?? ""
    self.value = dictionary["value"] as? String ?? ""
    self.enabled = dictionary["enabled"] as? Bool ?? false
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(value)
    hasher.combine(enabled)
  }
  
  static func == (lhs: VideoQualityData, rhs: VideoQualityData) -> Bool {
    return lhs.name == rhs.name && lhs.value == rhs.value && lhs.enabled == rhs.enabled
  }
}
