//
//  PlaybackErrorManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 04/02/24.
//

import Foundation
import AVKit
import React

public func extractPlayerItemError(_ item: AVPlayerItem?) -> [String: Any] {
  var playerError: [String: Any] = [:]
  if let error = item?.error as NSError? {
    playerError = ([
      "code": error.code,
      "userInfo": error.userInfo,
    ])
  }
  return playerError
}
