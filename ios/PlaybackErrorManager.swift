//
//  PlaybackErrorManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 04/02/24.
//

import Foundation
import AVKit
import React

public func extractPlayerErrors(_ item: AVPlayerItem?) -> [String: Any] {
  var playerError: [String: Any] = [:]
  if let error = item?.error as NSError? {
    playerError = ([
      "code": error.code,
      "userInfo": error.userInfo,
      "description": error.localizedDescription,
      "failureReason": error.localizedFailureReason,
      "fixSuggestion": error.localizedRecoverySuggestion
    ])
  }
  return playerError
}
