//
//  BridgeMethods.swift
//  Pods
//
//  Created by Michel Gutner on 26/11/24.
//
import Combine
import React
import AVFAudio
import AVKit

class RCTEvents {
  @objc var onVideoProgress: RCTBubblingEventBlock?
  @objc var onPlayPause: RCTBubblingEventBlock?
  @objc var onError: RCTDirectEventBlock?
  @objc var onBuffer: RCTDirectEventBlock?
  @objc var onCompleted: RCTDirectEventBlock?
  @objc var onFullscreen: RCTDirectEventBlock?
  @objc var onMenuItemSelected: RCTBubblingEventBlock?
  @objc var onMediaRouter: RCTBubblingEventBlock?
  @objc var onSeekBar: RCTBubblingEventBlock?
  @objc var onReady: RCTBubblingEventBlock?
  @objc var onPinchZoom: RCTBubblingEventBlock?
  
  private var isMediaRouteActive = false
  
  init(
    onVideoProgress: RCTBubblingEventBlock? = nil,
    onError: RCTDirectEventBlock? = nil,
    onBuffer: RCTDirectEventBlock? = nil,
    onCompleted: RCTDirectEventBlock? = nil,
    onFullscreen: RCTDirectEventBlock? = nil,
    onPlayPause: RCTDirectEventBlock? = nil,
    onMediaRouter: RCTDirectEventBlock? = nil,
    onSeekBar: RCTDirectEventBlock? = nil,
    onReady: RCTDirectEventBlock? = nil,
    onPinchZoom: RCTDirectEventBlock? = nil
  ) {
    self.onVideoProgress = onVideoProgress
    self.onError = onError
    self.onBuffer = onBuffer
    self.onCompleted = onCompleted
    self.onFullscreen = onFullscreen
    self.onPlayPause = onPlayPause
    self.onMediaRouter = onMediaRouter
    self.onSeekBar = onSeekBar
    self.onReady = onReady
    self.onPinchZoom = onReady
  }
  
  public func setupNotifications() {
    notificationObserver(forName: AVAudioSession.routeChangeNotification) { notification in
      self.checkActiveMediaRoute()
      DispatchQueue.main.async { [self] in
        let event: [String: Any] = [
          "isActive": isMediaRouteActive
        ]
        self.onMediaRouter?(event)
      }
    }

    notificationObserver(forName: AVPlayerItem.didPlayToEndTimeNotification) { [self] notification in
      sendCompleted()
    }
    
    notificationObserver(forName: .EventVideoProgress) { [self] notification in
      let progress = notification.userInfo?["progress"] as? CGFloat
      let buffering = notification.userInfo?["buffering"] as? CGFloat
      guard let progress, let buffering else { return }
      sendVideoProgress(progress, buffering)
    }
    
    notificationObserver(forName: .EventSeekBar) { [self] notification in
      let start = notification.userInfo?["start"] as! (percent: Double, seconds: Double)
      let ended = notification.userInfo?["ended"] as! (percent: CGFloat, seconds: Double)

      sendSeekbar(start: start, ended: ended)
    }
    
    notificationObserver(forName: .EventFullscreen) { [self] notification in
      let event = notification.object as! Bool
      sendFullscreen(event)
    }

    notificationObserver(forName: .EventPlayPause) { [self] notification in
      let event = notification.object as! Bool
      sendPlayPause(event)
    }
    
    notificationObserver(forName: .EventError) { [self] notification in
      let event = notification.object as! NSError
      sendError(event)
    }
    
    notificationObserver(forName: .EventReady) { [self] notification in
      let duration = notification.userInfo?["duration"] as! Double
      let ready = notification.userInfo?["ready"] as! Bool
      sendReady(duration, ready)
    }
    
    notificationObserver(forName: .EventPinchZoom) { [self] notification in
      let event = notification.userInfo?["currentZoom"] as! String
      sendPinchZoom(event)
    }
    
    notificationObserver(forName: .EventBuffer) { [self] notification in
      let buffering = notification.userInfo?["buffering"] as? Bool ?? false
      let completed = notification.userInfo?["completed"] as? Bool ?? false
      let empty = notification.userInfo?["empty"] as? Bool ?? false

      sendBufferEvent(buffering, completed, empty)
    }
  }
  
  private func notificationObserver(
    forName name: NSNotification.Name?,
    using block: @escaping @Sendable (Notification) -> Void
  ) {
    NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main, using: block)
  }
  
  private func checkActiveMediaRoute() {
    let session = AVAudioSession.sharedInstance()
    let outputs = session.currentRoute.outputs
    
    isMediaRouteActive = outputs.contains { output in
      return output.portType == .airPlay || output.portType == .bluetoothA2DP
    }
  }
  
  private func sendVideoProgress(_ progress: CGFloat, _ buffering: CGFloat) {
    DispatchQueue.main.async { [self] in
      let event: [String: Any] = [
        "progress": progress,
        "buffering": buffering
      ]
      self.onVideoProgress?(event)
    }
  }
  
  private func sendFullscreen(_ state: Bool) {
    DispatchQueue.main.async { [self] in
      let event: [String: Any] = [
        "isFullscreen": state
      ]
      
      self.onFullscreen?(event)
    }
  }
  
  private func sendReady(_ duration: CGFloat, _ loaded: Bool) {
    DispatchQueue.main.async { [self] in
      let event: [String: Any] = [
        "duration": duration,
        "loaded": loaded
      ]
      
      self.onReady?(event)
    }
  }
  
  private func sendPinchZoom(_ currentZoom: String) {
    DispatchQueue.main.async { [self] in
      let event: [String: Any] = [
        "currentZoom": currentZoom
      ]
      
      self.onPinchZoom?(event)
    }
  }
  
  func sendError(_ error: NSError) {
    let errorDetails: [String: Any] = [
      "domain": error.domain,
      "code": error.code,
      "userInfo": [
        "description": error.userInfo[NSLocalizedDescriptionKey],
        "failureReason": error.userInfo[NSLocalizedFailureReasonErrorKey],
        "fixSuggestion": error.userInfo[NSLocalizedRecoverySuggestionErrorKey]
      ]
    ]
    DispatchQueue.main.async {
      self.onError?(errorDetails)
    }
  }
  
  func sendBufferEvent(_ buffering: Bool, _ completed: Bool, _ empty: Bool) {
    DispatchQueue.main.async {
      let event: [String: Any] = [
        "buffering": buffering,
        "completed": completed,
        "empty": empty
      ]
      self.onBuffer?(event)
    }
  }
  
  private func sendCompleted() {
    DispatchQueue.main.async { [self] in
      let event: [String: Any] = [
        "completed": true,
      ]
      self.onCompleted?(event)
    }
  }
  
  private func sendPlayPause(_ event: Bool) {
    DispatchQueue.main.async {
      let event: [String: Any] = [
        "isPlaying": event
      ]
      
      self.onPlayPause?(event)
    }
  }
  
  private func sendSeekbar(start: (percent: Double, seconds: Double), ended: (percent: CGFloat, seconds: Double)) {
    DispatchQueue.main.async { [self] in
      let event: [String: Any] = [
        "start": ["percent": start.percent * 100, "seconds": start.seconds],
        "ended": ["percent": ended.percent * 100, "seconds": ended.seconds]
      ]
      
      onSeekBar?(event)
    }
  }
}
