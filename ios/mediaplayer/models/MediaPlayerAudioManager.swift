//
//  MediaPlayerAudioManager.swift
//  Pods
//
//  Created by Michel Gutner on 15/01/25.
//
import AVFoundation

/// Manager the audio  (`AVAudioSession`) .
open class MediaPlayerAudioManager {
  fileprivate var audioSession = AVAudioSession.sharedInstance()
  fileprivate var errorDetails: [String: Any] = [:]
  
  public init () {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioRouteChangeNotification(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )
  }
  
  @objc func handleAudioRouteChangeNotification(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? Int,
          let reason = AVAudioSession.RouteChangeReason(rawValue: UInt(reasonValue)) else { return }
    
    switch reason {
    case .newDeviceAvailable: break
    case .oldDeviceUnavailable: break
    default: break
    }
  }
  
  open func activateAudioSession() {
    do {
      try audioSession.setCategory(.playback, mode: .default, options: [])
      try audioSession.setActive(true)
      Debug.log("[MediaPlayerAudioManager] Audio session active successfully.")
    } catch let error as NSError {
      let errorDetails: [String: Any] = [
        NSLocalizedDescriptionKey: "Unable to activate the audio session.",
        NSLocalizedFailureReasonErrorKey: "An error occurred while activating the audio session.",
        NSLocalizedRecoverySuggestionErrorKey: "Check if another process is using the audio session or ensure the configuration is correct.",
        NSUnderlyingErrorKey: error
      ]
      Debug.log("[MediaPlayerAudioManager] Failed to active audio session: \(String(describing: errorDetails))")
    }
  }
  
  
  open func deactivateAudioSession() {
    do {
      try audioSession.setActive(false)
      Debug.log("[MediaPlayerAudioManager] Audio session deactivated successfully.")
    } catch let error as NSError {
      errorDetails = [
        NSLocalizedDescriptionKey: "Unable to deactivate the audio session.",
        NSLocalizedFailureReasonErrorKey: "An error occurred while deactivating the audio session.",
        NSLocalizedRecoverySuggestionErrorKey: "Ensure no other processes are holding the audio session.",
        NSUnderlyingErrorKey: error
      ]
      Debug.log("[MediaPlayerAudioManager] Failed to deactivate audio session: \(String(describing: errorDetails))")
    }
  }
}
