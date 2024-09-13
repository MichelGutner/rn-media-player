//
//  PlaybackObservable.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 12/02/24.
//

import Foundation
import AVFoundation

class PlaybackObserver: ObservableObject {
    @Published var playbackStatus = AVPlayerItem.Status.unknown
    @Published var deviceOrientation = UIDevice.current.orientation.isPortrait
    @Published var isFinished: Bool = false
    
    
    @objc func playbackItem(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        playbackStatus = item.status
    }
    
    @objc func deviceOrientation(_ notification: Notification) {
        // Lógica para lidar com a mudança de orientação do dispositivo
        if let device = notification.object as? UIDevice {
            deviceOrientation = device.orientation.isPortrait
        }
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        let avPlayerItem = notification.object as? AVPlayerItem
        isFinished = true
    }
}


public func notificationPostModal(userInfo: [String: Any]) {
  NotificationCenter.default.post(name: Notification.Name("modal"), object: nil, userInfo: userInfo)
}

public func notificationPostPlaybackInfo(userInfo: [String: Any]) {
  NotificationCenter.default.post(name: Notification.Name("playbackInfo"), object: nil, userInfo: userInfo)
}
