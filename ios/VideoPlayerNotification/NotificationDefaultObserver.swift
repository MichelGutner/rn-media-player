//
//  NotificationDefaultObserver.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 26/02/24.
//

import Foundation

@available(iOS 13.0, *)
public func NotificationDefaultObserver(selector: Selector, name: NSNotification.Name?, object: Any?) {
  NotificationCenter.default.addObserver(PlayerObserver(), selector: selector, name: name, object: object)
}
