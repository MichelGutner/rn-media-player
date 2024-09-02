//
//  UtilityEnums.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 21/02/24.
//

import Foundation

@available(iOS 14.0, *)
enum SettingsOption: String {
  case qualities,
       speeds,
       moreOptions
}

enum Resize: String {
  case contain, cover, stretch
}

enum RNVideoUrlError: Error {
  case invalidURL
  case invalidPlayer
}
