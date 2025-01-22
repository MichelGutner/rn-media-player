//
//  MediaPlayerAudioManager.swift
//  Pods
//
//  Created by Michel Gutner on 15/01/25.
//
import AVFoundation

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
    
  open func activateAudioSession(onCompletion: @escaping (_ isSuccess: Bool, _ error: [String: Any]) -> Void) {
    do {
      try audioSession.setCategory(.playback, mode: .default, options: [])
      try audioSession.setActive(true)
      onCompletion(true, [:])
    } catch let error as NSError {
      let errorDetails: [String: Any] = [
        NSLocalizedDescriptionKey: "Unable to activate the audio session.",
        NSLocalizedFailureReasonErrorKey: "An error occurred while activating the audio session.",
        NSLocalizedRecoverySuggestionErrorKey: "Check if another process is using the audio session or ensure the configuration is correct.",
        NSUnderlyingErrorKey: error
      ]
      onCompletion(false, errorDetails)
    }
  }

    
    open func deactivateAudioSession(onCompletion: @escaping (_ isSuccess: Bool, _ error: [String: Any]) -> Void) {
        do {
            try audioSession.setActive(false)
            onCompletion(true, [:])
        } catch let error as NSError {
            errorDetails = [
                NSLocalizedDescriptionKey: "Unable to deactivate the audio session.",
                NSLocalizedFailureReasonErrorKey: "An error occurred while deactivating the audio session.",
                NSLocalizedRecoverySuggestionErrorKey: "Ensure no other processes are holding the audio session.",
                NSUnderlyingErrorKey: error
            ]
            onCompletion(false, errorDetails)
        }
    }
}
