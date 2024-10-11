//
//  PlaybackObservable.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 12/02/24.
//

import Foundation
import AVFoundation

class PlaybackObserver: ObservableObject {    @Published var playbackStatus = AVPlayerItem.Status.unknown
    @Published var deviceOrientation = UIDevice.current.orientation.isPortrait
    @Published var isFinished: Bool = false
    @Published var changedRate: Float = 0.0
    
    
    @objc func playbackItem(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        playbackStatus = item.status
    }
    
    @objc func deviceOrientation(_ notification: Notification) {
        if let device = notification.object as? UIDevice {
            deviceOrientation = device.orientation.isPortrait
        }
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        isFinished = true
    }
    
    @objc func handleRateChangeNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo, let rate = userInfo["rate"] as? Float {
            changedRate = rate
        }
    }
}
