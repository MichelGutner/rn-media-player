//
//  RNMediaPlayerView.swift
//  Pods
//
//  Created by Michel Gutner on 22/01/25.
//

import SwiftUI
import UIKit
import AVFoundation
import MediaPlayer

@available(iOS 14.0, *)
class RNMediaPlayerView : RCTPropsView {
  fileprivate var mediaSource = MediaSource()
  fileprivate var playerLayerVC: MediaPlayerLayerViewController?
  fileprivate var controlsVC: UIHostingController<MediaPlayerControlsView>?
  fileprivate var rootControlsView: MediaPlayerControlsView?
  fileprivate var videoThumbnailGenerator: VideoThumbnailGenerator?
  fileprivate var remoteControls: RemoteControlManager?
  fileprivate var menuControl: MenuOptionsControlView?
  
  @objc var controlsStyles: NSDictionary? = [:]
  
  
  @objc var doubleTapToSeek: NSDictionary? = nil {
    didSet {
      if oldValue != doubleTapToSeek {
        RCTConfigManager.setDoubleTapToSeek(with: doubleTapToSeek)
      }
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.rctPropsViewDelegate = self
    addNotificationsObservers()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    playerLayerVC?.view.frame = bounds
    super.layoutSubviews()
  }
  
  override func removeFromSuperview() {
    mediaSource.prepareToDeInit()
    playerLayerVC?.prepareToDeInit()
    videoThumbnailGenerator?.cancel()
    ThumbnailManager.clearImages()
    remoteControls?.prepareToDeInit()
    menuControl = nil
  }
  
  private func initializerDelegates() {
    Debug.isEnabled = true
    rootControlsView = MediaPlayerControlsView(mediaSource: mediaSource)
    rootControlsView?.delegate = self
    
    controlsVC = UIHostingController(rootView: rootControlsView!)
    
    mediaSource.delegate = self
    remoteControls?.delegate = self
    menuControl?.delegate = self
    
    if let playerLayerVC {
      playerLayerVC.addContentOverlayController(with: controlsVC!)
      playerLayerVC.delegate = self
      addSubview(playerLayerVC.view)
    }
    
    menuControl?.bounds = bounds
    
    remoteControls?.makeNowPlayingInfo()
  }
  
  private func addNotificationsObservers() {
//    NotificationCenter.default.addObserver(self, selector: #selector(didEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationChanged(_ :)), name: UIDevice.orientationDidChangeNotification, object: nil)
  }
  
  @objc fileprivate func onDeviceOrientationChanged(_ notification: Notification) {
    guard let layer = self.playerLayerVC else { return }
    let uiDevice = notification.object as! UIDevice
    
    if (uiDevice.orientation.isLandscape) {
      DispatchQueue.main.async {
        if (!layer.isFullscreen) {
          self.playerLayerVC?.didPresentFullscreen()
        }
      }
    } else {
      DispatchQueue.main.async {
        if (layer.isFullscreen) {
          self.playerLayerVC?.didDismissFullscreen()
        }
      }
    }
  }
  
  @objc fileprivate func didEnterForeground() {
    mediaSource.setPlaybackState(to: .playing)
  }
  
  @objc fileprivate func didEnterBackground() {
    mediaSource.setPlaybackState(to: .waiting)
  }
}

@available(iOS 14.0, *)
extension RNMediaPlayerView : MenuOptionsControlViewDelegate {
  func onMenuOptionSelected(option: EMenuOptionItem, name: String, value: Any) {
    switch option {
    case .speeds:
      mediaSource.setRate(to: value as! Float)
      break
    case .captions:
      if let elegibleGroup = menuControl?.selectionGroup {
        mediaSource.playerItem?.select(value as? AVMediaSelectionOption, in: elegibleGroup)
      }
      break
    case .qualities:
      mediaSource.setPlayerWithNewURL(value as! String) { success, error in
        if success {
          Debug.log("[PlayerSource] Player updated successfully.")
        } else if let error = error {
          self.sendEvent(.onMediaError, error)
        }
      }
      break
    case .unkown:
      Debug.log("unkown option selected")
      break
    }
  }
}

@available(iOS 14.0, *)
extension RNMediaPlayerView : RCTPropsViewDelegate {
  func onRate(_ rate: Float) {
    mediaSource.setRate(to: rate)
  }
  
  func onAutoPlay(_ didPlay: Bool) {
    if didPlay {
      mediaSource.setPlaybackState(to: .playing)
    }
  }
  
  func onSource(_ source: NSDictionary?) {
    mediaSource.setup(with: source) { [self] player in
      playerLayerVC = MediaPlayerLayerViewController(player: player)
      remoteControls = RemoteControlManager(player: player)
      menuControl = MenuOptionsControlView(player: player)
      initializerDelegates()
    }
  }

  func onThumbnails(_ url: String) {
    videoThumbnailGenerator = VideoThumbnailGenerator(videoURL: url) { image, completed in
      ThumbnailManager.setImage(image)
      if completed {
        Debug.log("[Thumbnails] all images generated successfully")
      }
    }
  }
  
  func onEntersFullScreenWhenPlaybackBegins(_ didEnterFullscreen: Bool) {
    if didEnterFullscreen {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
        self.playerLayerVC?.didPresentFullscreen()
      })
    }
  }
}

@available(iOS 14.0, *)
extension RNMediaPlayerView: RemoteControlManagerDelegate {
  func remoteControls(_ remoteControls: RemoteControlManager, didReceive command: RemoteControlCommand) {
    switch command {
    case .play:
      mediaSource.setPlaybackState(to: .playing)
    case .pause:
      mediaSource.setPlaybackState(to: .paused)
    case .skipForward: break
    case .skipBackward: break
    }
  }
}

@available(iOS 14.0, *)
extension RNMediaPlayerView: MediaPlayerLayerViewControllerDelegate {
  func playerLayerControlView(_ playerLayer: MediaPlayerLayerViewController, didRequestControl action: PlayerLayerViewControllerActionType, didChangeState state: Any?) {
    switch action {
    case .pinchToZoom:
      sendEvent(.onMediaPinchZoom, state!)
    case .fullscreen:
      sendEvent(.onFullScreenStateChanged, ["isFullscreen": state])
      DispatchQueue.main.async {
        SharedScreenState.setFullscreenState(to: state as? Bool ?? false)
      }
    }
  }
}

@available(iOS 14.0, *)
extension RNMediaPlayerView: MediaSourceDelegate {
  func mediaPlayer(_ control: MediaSource, currentTime: Double, duration: Double, bufferingProgress: CGFloat) {
    let timeInfo: [String: Any] = ["totalBuffered": bufferingProgress, "progress": currentTime]
    let bufferCompleted: [String: Any] = ["completed": bufferingProgress >= duration]
    sendEvent(.onMediaBuffering, timeInfo)
    sendEvent(.onMediaBufferCompleted, bufferCompleted)
    remoteControls?.setPlaybackTimes(currentTime: currentTime, duration: duration)
  }
  
  func mediaPlayer(_ player: MediaSource, didChangeReadyToDisplay isReadyToDisplay: Bool) {
    menuControl?.createOptions(with: menuOptions)
    
    PlaybackManager.setIsReadyForDisplay(to: isReadyToDisplay)
    sendEvent(.onMediaReady, ["loaded": isReadyToDisplay, "duration": player.playerItem?.duration.seconds ?? 0.0])
    Debug.log("[PlayerSourceDelegate] isReadyToDisplay -> \(isReadyToDisplay)")
  }
  
  func mediaPlayer(_ player: MediaSource, loadFail error: (any Error)?) {
    sendEvent(.onMediaError, error as Any)
  }
  
  func mediaPlayer(_ player: MediaSource, didChangePlaybackState state: PlaybackState) {
    let isFinished = state == .ended
    if isFinished {
      sendEvent(.onMediaCompleted, ["completed": true])
    }
    PlaybackManager.updateIsPlaying(to: state == .playing)
  }
  
  func mediaPlayer(_ player: MediaSource, playerItemMetadata: [AVMetadataItem]?) {
    let title = playerItemMetadata?.first { $0.identifier == .commonIdentifierTitle }?.stringValue ?? ""
    let artist = playerItemMetadata?.first {$0.identifier == .commonIdentifierArtist }?.stringValue ?? ""
    SharedMetadataIdentifier.setMetadata(title: title, artist: artist)
  }
}

@available(iOS 14.0, *)
extension RNMediaPlayerView : MediaPlayerControlsViewDelegate {
  func controlDidTap(_ control: MediaPlayerControlsView, controlType: MediaPlayerControlButtonType, didChangeControlEvent event: Any?) {
    switch controlType {
    case .playPause:
      switch mediaSource.playbackState {
      case .playing:
        mediaSource.setPlaybackState(to: .paused)
        sendEvent(.onMediaPlayPause, false)
        break
      case .paused:
        mediaSource.setPlaybackState(to: .playing)
        sendEvent(.onMediaPlayPause, true)
        break
      case .waiting:
        mediaSource.setPlaybackState(to: .playing)
        sendEvent(.onMediaPlayPause, true)
        break
      case .ended: mediaSource.setPlaybackState(to: .replay)
      case .error: break
      case .replay: break
      case .none:
        mediaSource.setPlaybackState(to: .playing)
        sendEvent(.onMediaPlayPause, true)
        break
      }
    case .fullscreen:
      if event as! Bool {
        playerLayerVC?.didPresentFullscreen()
      } else {
        playerLayerVC?.didDismissFullscreen()
      }
    case .optionsMenu:
      menuControl?.present()
      break
    case .seekGestureBackward:
      mediaSource.onBackwardTime(event as! Int)
      break
    case .seekGestureForward:
      mediaSource.onForwardTime(event as! Int)
      break
    }
  }
  
  func sliderDidChange(_ control: MediaPlayerControlsView, didChangeProgressFrom fromValue: Double, didChangeProgressTo toValue: Double) {
    let lastProgressInSeconds = fromValue * (mediaSource.playerItem?.duration.seconds ?? 0)
    let progressInSeconds = toValue * (mediaSource.playerItem?.duration.seconds ?? 0)
    
    let sliderProgressInfo = ["start": ["percent": fromValue, "seconds": lastProgressInSeconds], "ended": ["percent": toValue, "seconds": progressInSeconds]]
    self.sendEvent(.onMediaSeekBar, sliderProgressInfo)
  }
}
