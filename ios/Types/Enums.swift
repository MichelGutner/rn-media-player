//
//  UtilityEnums.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 21/02/24.
//

import Foundation

enum Resize: String {
  case contain, cover, stretch
}

enum RNVideoUrlError: Error {
  case invalidURL
  case invalidPlayer
}
