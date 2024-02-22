//
//  UtilityEnums.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 21/02/24.
//

import Foundation


@available(iOS 13.0, *)
public struct HashableItem: Hashable {
  var name: String
  var value: String?
  var enabled: Bool?
}

@available(iOS 13.0, *)
enum ESettingsOptions: String {
  case quality,
       playbackSpeed,
       moreOptions
}

enum Resize: String {
  case contain, cover, stretch
}

enum VideoPlayerError: Error {
  case invalidURL
  case invalidPlayer
}
