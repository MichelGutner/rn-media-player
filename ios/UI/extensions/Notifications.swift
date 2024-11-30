//
//  Notifications.swift
//  Pods
//
//  Created by Michel Gutner on 10/10/24.
//

extension Notification.Name {
  static let AVPlayerRateDidChange = Notification.Name("AVPlayerRateDidChange")
  static let AVPlayerTimeControlStatus = Notification.Name("AVPlayerTimeControlStatus")
  static let AVPlayer = Notification.Name("player")
  static let PlayerItem = Notification.Name("PlayerItem")
  static let UIScreen = Notification.Name("UIScreen")
  static let AVPlayerThumbnails = Notification.Name("AVPlayerThumbnails")
  static let AVPlayerControlsVisible = Notification.Name("AVPlayerControlsVisible")
  static let DoubleTapNotification = Notification.Name("DoubleTapNotification")
  static let AVPlayerUrlChanged = Notification.Name("AVPlayerUrlChanged")
  static let AVPlayerErrors = Notification.Name("AVPlayerErrors")
  static let SeekingNotification = Notification.Name("SeekingNotification")
  static let AVPlayerInitialLoading = Notification.Name("AVPlayerLoading")
  static let AVPlayerSource = Notification.Name("AVPlayerSource")
  
  
  static let FullscreenState = Notification.Name("FullscreenState")
  static let PlayerLayerReadyForDisplay = Notification.Name("PlayerLayerReadyForDisplay")
  // Events
  static let EventMenuSelectOption = Notification.Name("EventMenuSelectOption")
  static let EventSeekBar = Notification.Name("EventSeekBar")
  static let EventVideoProgress = Notification.Name("EventVideoProgress")
  static let EventFullscreen = Notification.Name("EventFullscreen")
  static let EventPlayPause = Notification.Name("EventPlayPause")
  static let EventError = Notification.Name("EventError")
  static let EventReady = Notification.Name("EventReady")
  static let EventPinchZoom = Notification.Name("EventPinchZoom")
  static let EventBuffer = Notification.Name("EventBuffer")
}
