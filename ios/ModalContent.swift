//
//  SpeedRateData.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 30/01/24.
//

struct HashableContent : Hashable {
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
  
  static func == (lhs: HashableContent, rhs: HashableContent) -> Bool {
    return lhs.name == rhs.name && lhs.value == rhs.value && lhs.enabled == rhs.enabled
  }
}

struct HashableOption : Hashable {
  let name: String
  let value: String
  let enabled: Bool
  
  init(name: String, value: String, enabled: Bool) {
    self.name = name
    self.value = value
    self.enabled = enabled
  }
  
  init(dictionary: NSDictionary) {
      print("DIC", dictionary)
    self.name = dictionary["name"] as? String ?? ""
    self.value = dictionary["value"] as? String ?? ""
    self.enabled = dictionary["enabled"] as? Bool ?? false
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(value)
    hasher.combine(enabled)
  }
}
