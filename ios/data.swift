//
//  SpeedRateData.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 30/01/24.
//

@available(iOS 13.0, *)
public var settingsData: [HashableItem] = [
  HashableItem(name: "Quality", value: "qualities", enabled: true),
  HashableItem(name: "Playback speed", value: "speeds", enabled: true),
  HashableItem(name: "More Options", value: "moreOptions", enabled: true)
]


struct OptionSelection : Hashable {
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
  
  static func == (lhs: OptionSelection, rhs: OptionSelection) -> Bool {
    return lhs.name == rhs.name && lhs.value == rhs.value && lhs.enabled == rhs.enabled
  }
}
