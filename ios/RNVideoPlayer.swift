import AVKit
import SwiftUI
import UIKit
import React
import AVFoundation

@available(iOS 13.0, *)
@objc(RNVideoPlayer)
class RNVideoPlayer: RCTViewManager {
  @objc override func view() -> (RNVideoPlayerView) {
    return RNVideoPlayerView()
  }
  
  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}

@available(iOS 13.0, *)
class RNVideoPlayerView: UIView, UIGestureRecognizerDelegate {
  private var hasCalledSetup = false
  private var player: AVPlayer?
  private var timeObserver: Any?
  private var playerLayer: AVPlayerLayer!
  
  private var isRotated = false
  private var isSeeking: Bool = false
  private var loading = true
  private var isOpenedModal = false
  private var playerStatus: AVPlayer.TimeControlStatus?
  
  private var settingsOpened = false
  private var optionsData: [HashableData] = []
  
  private var initialQualitySelected = ""
  private var initialSpeedSelected = ""
  private var selectedQuality: String = ""
  private var selectedSpeed: String = ""
  
  private var videoQualities: [HashableData] = []
  private var videoSpeeds: [HashableData] = []
  private var videoSettings: [HashableData] = []
  
  private var loadingView = UIView()
  private var url: URL?
  
  private var title = UILabel()
  private var thumbnailsFrames: [UIImage] = []
  
  private var playerView = UIView()
  
  @objc var onVideoProgress: RCTBubblingEventBlock?
  @objc var onLoaded: RCTBubblingEventBlock?
  @objc var onReady: RCTDirectEventBlock?
  @objc var onCompleted: RCTBubblingEventBlock?
  @objc var onSettingsTapped: RCTDirectEventBlock?
  @objc var onFullScreenTapped: RCTDirectEventBlock?
  @objc var onError: RCTDirectEventBlock?
  @objc var onBuffer: RCTDirectEventBlock?
  @objc var onBufferCompleted: RCTDirectEventBlock?
  @objc var onGoBackTapped: RCTDirectEventBlock?
  @objc var onVideoDownloaded: RCTDirectEventBlock?
  @objc var onPlaybackSpeedTapped: RCTDirectEventBlock?
  @objc var onDownloadVideoTapped: RCTDirectEventBlock?
  @objc var onQualityTapped: RCTDirectEventBlock?
  @objc var onPlayPause: RCTDirectEventBlock?
  
  private var viewController: RCTWrapperViewController?
  
  @objc var advanceValue: NSNumber? = 0
  @objc var suffixAdvanceValue: String? = "seconds"
  
  @objc var thumbnailFramesSeconds: Float = 1.0
  @objc var enterInFullScreenWhenDeviceRotated: Bool = false
  @objc var autoPlay: Bool = true
  @objc var loop: Bool = false
  
  @objc var sliderProps: NSDictionary? = [:]
  @objc var playPauseProps: NSDictionary? = [:]
  @objc var labelProgressProps: NSDictionary? = [:]
  @objc var labelDurationProps: NSDictionary? = [:]
  @objc var settingsSymbolProps: NSDictionary? = [:]
  @objc var fullScreenProps: NSDictionary? = [:]
  @objc var titleProps: NSDictionary? = [:]
  @objc var goBackProps: NSDictionary? = [:]
  @objc var loadingProps: NSDictionary? = [:]
  @objc var speeds: NSDictionary? = [:]
  @objc var qualities: NSDictionary? = [:]
  @objc var settings: NSDictionary? = [:]
  
  // external controls
  @objc var source: NSDictionary? = [:] {
    didSet {
      do {
        let playbackUrl = source?["url"] as? String
        let verificatedUrlString = try verifyUrl(urlString: playbackUrl)
        let cached = PlayerFileManager().videoCached(title: "TestVideo")
        
        if cached.fileExist {
          player = AVPlayer(url: URL(string: "file://\(cached.path)")!)
        } else {
          player = AVPlayer(url: verificatedUrlString)
        }
        
        player?.actionAtItemEnd = .none
        hasCalledSetup = true
        
        player?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        player?.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        player?.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        player?.currentItem?.addObserver(self, forKeyPath: "playbackBufferFull", options: .new, context: nil)
        playerLayer = AVPlayerLayer(player: player)
      } catch {
        print("e", error)
        self.onError?(["url": "Error on get url: error type is \(error)"])
      }
    }
  }
  
  private var observer = PlaybackObserver()
  
  @objc var rate: Float = 0.0 {
    didSet{
      self.onChangeRate(rate)
    }
  }
  
  @objc var paused: Bool = false {
    didSet {
      self.onPaused(paused)
    }
  }
  
  @objc var resizeMode: NSString = "contain"
  
  @objc var startTime: Float = 0.0 {
    didSet {
      player?
        .currentItem?.seek(
          to: CMTime(seconds: Double(startTime), preferredTimescale: 1),
          completionHandler: nil
        )
    }
  }
  
  private var buffering: Double = 0.0
  private var currentTime: Double = 0.0
  private var duration: Double = 0.0
  private var playbackFinished: Bool = false
  private var isFullScreen = false
  private var videoPlayerView = UIView()
  private var openedOptionsQualities: Bool = false
  private var openedOptionsSpeed: Bool = false
  private var openedOptionsMoreOptions: Bool = false
  private var sliderProgress: Double = 0.0
  private var lastDraggedProgress: Double = 0.0
  private var isPlaying: Bool? = nil
  
  @objc func toggleFullScreen(_ fullScreen: Bool) {
    if fullScreen {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: { [self] in
        videoPlayerView.removeFromSuperview()
        
        videoPlayerView.frame = UIScreen.main.bounds
        superview?.addSubview(videoPlayerView)
      })
    } else {
      videoPlayerView.removeFromSuperview()
      
      if frame.height > UIScreen.main.bounds.height {
        videoPlayerView.frame = UIScreen.main.bounds
      } else {
        videoPlayerView.frame = frame
      }
      
      superview?.addSubview(videoPlayerView)
    }
    
    isFullScreen = fullScreen
    onFullScreenTapped?(["fullScreen": fullScreen])
  }
  
  override func layoutSubviews() {
    guard let player = player else { return }
    videoPlayerView.removeFromSuperview()
    
    if let initialQualityOption = qualities?["initialSelected"] as? String  {
      initialQualitySelected = initialQualityOption
    }
    
    if let initialSpeedOption = speeds?["initialSelected"] as? String {
      initialSpeedSelected = initialSpeedOption
    }
    
    if let qualitiesData = qualities?["data"] as? [[String: Any]] {
      videoQualities = qualitiesData.map { HashableData(dictionary: $0) }
    }
    
    if let speedsData = speeds?["data"] as? [[String: Any]] {
      videoSpeeds = speedsData.map { HashableData(dictionary: $0) }
    }
    
    if let settingsData = settings?["data"] as? [[String: Any]] {
      self.videoSettings = settingsData.map { HashableData(dictionary: $0) }
    }
    
    let mode = Resize(rawValue: resizeMode as String)
    let videoGravity = self.videoGravity(mode!)
    
    let playerView = UIHostingController(
      rootView: CustomView(
        player: player,
        currentTime: currentTime,
        duration: duration,
        playbackFinished: playbackFinished,
        buffering: buffering,
        videoGravity: videoGravity,
        thumbnails: thumbnailsFrames,
        onTapFullScreenControl: { [self] state in
          toggleFullScreen(state)
        },
        isFullScreen: isFullScreen,
        videoSettings: videoSettings,
        onTapSettingsControl: onTapSettings,
        videoQualities: videoQualities,
        initialQualitySelected: initialQualitySelected,
        videoSpeeds: videoSpeeds,
        initialSpeedSelected: initialSpeedSelected,
        selectedQuality: selectedQuality,
        selectedSpeed: selectedSpeed,
        settingsModalOpened: settingsOpened,
        openedOptionsQualities: openedOptionsQualities,
        openedOptionsSpeed: openedOptionsSpeed,
        openedOptionsMoreOptions: openedOptionsMoreOptions,
        isActiveAutoPlay: autoPlay,
        isActiveLoop: loop,
        sliderProgress: sliderProgress,
        lastDraggedProgress: lastDraggedProgress,
        isPlaying: isPlaying
      )
    )
    videoPlayerView = playerView.view
    videoPlayerView.backgroundColor = .black
    videoPlayerView.clipsToBounds = true
    
    if videoPlayerView.frame == .zero {
      if frame.height > UIScreen.main.bounds.height {
        videoPlayerView.frame = UIScreen.main.bounds
      } else {
        videoPlayerView.frame = frame
      }
      superview?.addSubview(playerView.view)
    }

    NotificationCenter.default.addObserver(forName: Notification.Name("modal"), object: nil, queue: .main) { [self] modalNotification in
      if let optionsQualitySelected = (modalNotification.userInfo?["optionsQualitySelected"] as? String) {
        self.selectedQuality = optionsQualitySelected
      }
      
      if let qualityUrlToChange = modalNotification.userInfo?["qualityUrl"] as? String {
        self.changePlaybackQuality(URL(string: qualityUrlToChange)!)
      }
      
      if let speedRate = (modalNotification.userInfo?["speedRate"] as? Float) {
        self.onChangeRate(speedRate)
      }
      
      if let optionsSpeedSelected = (modalNotification.userInfo?["optionsSpeedSelected"] as? String) {
        self.selectedSpeed = optionsSpeedSelected
      }
      
      if let openedModal = (modalNotification.userInfo?["opened"] as? Bool) {
        self.settingsOpened = openedModal
      }
      
      if let openedOptionsSpeed = (modalNotification.userInfo?["\(ESettingsOptions.speeds)Opened"] as? Bool) {
        self.openedOptionsSpeed = openedOptionsSpeed
      }
      
      if let openedOptionsQualities = (modalNotification.userInfo?["\(ESettingsOptions.qualities)Opened"] as? Bool) {
        self.openedOptionsQualities = openedOptionsQualities
      }
      
      if let moreOptions = (modalNotification.userInfo?["\(ESettingsOptions.moreOptions)Opened"] as? Bool) {
        self.openedOptionsMoreOptions = moreOptions
      }
      
      if let optionsAutoPlay = modalNotification.userInfo?["optionsAutoPlay"] as? Bool {
        self.autoPlay = optionsAutoPlay
      }
      
      if let optionsLoop = modalNotification.userInfo?["optionsLoop"] as? Bool {
        self.loop = optionsLoop
      }
      
    }
    
    NotificationCenter.default.addObserver(forName: Notification.Name("playbackInfo"), object: nil, queue: .main) { [self] notification in
      if let buffering = notification.userInfo?["buffering"] as? Double {
        self.buffering = buffering
      }
      
      if let currentTime = notification.userInfo?["currentTime"] as? Double {
        self.currentTime = currentTime
      }
      
      if let duration = notification.userInfo?["duration"] as? Double {
        self.duration = duration
      }
      
      if let finished = notification.userInfo?["playbackFinished"] as? Bool {
        self.playbackFinished = finished
      }
      
      if let sliderProgress = notification.userInfo?["sliderProgress"] as? Double {
        self.sliderProgress = sliderProgress
      }
      
      if let lastDraggedProgress = notification.userInfo?["lastDraggedProgress"] as? Double {
        self.lastDraggedProgress = lastDraggedProgress
      }
      
      if let isPlaying = notification.userInfo?["isPlaying"] as? Bool {
        self.isPlaying = isPlaying
      }
      
      if !playbackFinished {
        self.onVideoProgress?(["buffering": buffering, "progress": currentTime])
      }
      
    }
    
    NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: .main) { [self] notification in
      DispatchQueue.main.async { [self] in
        NotificationCenter.default.post(name: Notification.Name("frames"), object: nil, userInfo: ["frames": thumbnailsFrames])
      }
    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    
    if hasCalledSetup {
      enableAudioSession()
      videoPlayerSubView()
    }
  }
  
  private func generatingThumbnailsFrames() {
    Task.detached { [self] in
      guard let asset = await player?.currentItem?.asset else { return }
      
      do {
        let totalDuration = asset.duration.seconds
        var framesTimes: [NSValue] = []
        
        // Generate thumbnails frames
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = .init(width: 250, height: 250)
        
        
        for progress in await stride(from: 0, to: totalDuration / Double(thumbnailFramesSeconds * 100), by: 0.01) {
          let time = CMTime(seconds: totalDuration * Double(progress), preferredTimescale: 600)
          framesTimes.append(time as NSValue)
        }
        let localFrames = framesTimes
        
        generator.generateCGImagesAsynchronously(forTimes: localFrames) { requestedTime, image, _, _, error in
          guard let cgImage = image, error == nil else {
            return
          }
          
          DispatchQueue.main.async { [self] in
            let uiImage = UIImage(cgImage: cgImage)
            thumbnailsFrames.append(uiImage)
            
            NotificationCenter.default.post(name: Notification.Name("frames"), object: nil, userInfo: ["frames": thumbnailsFrames])
          }
          
        }
      }
    }
  }
  
  private func videoPlayerSubView() {
    let loading = UIHostingController(rootView: CustomLoading(config: loadingProps))
    loading.view.frame = bounds
    loading.view.backgroundColor = .clear
    loadingView = loading.view
    loadingView.isHidden = !self.loading
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if object is AVPlayerItem {
      switch keyPath {
      case "playbackBufferEmpty":
        onBuffer?(["buffering": true])
      case "playbackLikelyToKeepUp":
        onBuffer?(["buffering": false])
      case "playbackBufferFull":
        onBufferCompleted?(["completed": true])
      case .none:
        break
      case .some(_):
        break
      }
    }
    if keyPath == "status", let player = player {
      if player.status == .readyToPlay {
        self.loading = false
        //        onLoadingManager(hideLoading: true)
        onLoaded?(["duration": player.currentItem?.duration.seconds as Any])
        onReady?(["ready": true])
        generatingThumbnailsFrames()
      } else if player.status == .failed {
        self.onError?(extractPlayerErrors(player.currentItem))
      } else if player.status == .unknown {
        self.onError?(extractPlayerErrors(player.currentItem))
      }
    }
  }
  
  @objc private func itemDidFinishPlaying(_ notification: Notification) {
    self.playbackFinished = true
    self.onCompleted?(["completed": true])
  }
  
  private func enableAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers, .allowAirPlay])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      onError?(["error": "cant able to enable audio background session \(error)"])
    }
  }
}



// player method from bridge
@available(iOS 13.0, *)
extension RNVideoPlayerView {
  @objc private func onPaused(_ paused: Bool) {
    if paused {
      player?.pause()
    } else {
      player?.play()
    }
  }
  
  @objc private func onChangeRate(_ rate: Float) {
    self.player?.rate = rate
  }
}

// player methods
@available(iOS 13.0, *)
extension RNVideoPlayerView {
  @objc private func onTapSettings() {
    onSettingsTapped?([:])
    settingsOpened = true
  }
  
  @objc private func onTapGoback() {
    onGoBackTapped?([:])
  }
  
  @objc private func orientationDidChange() {
    let currentOrientation = UIDevice.current.orientation
    videoPlayerView.removeFromSuperview()
    
    if currentOrientation == .portrait || currentOrientation == .portraitUpsideDown {
      DispatchQueue.main.asyncAfter(deadline: .now()) { [self] in
        toggleFullScreen(false)
      }
    } else {
      if enterInFullScreenWhenDeviceRotated {
        DispatchQueue.main.asyncAfter(deadline: .now()) { [self] in
          toggleFullScreen(true)
        }
      } else {
        DispatchQueue.main.asyncAfter(deadline: .now()) { [self] in
          toggleFullScreen(false)
        }
      }
    }
  }
}

@available(iOS 13.0, *)
extension RNVideoPlayerView {
  func videoGravity(_ videoResize: Resize) -> AVLayerVideoGravity  {
    switch (videoResize) {
    case .stretch:
      return .resize
    case .cover:
      return .resizeAspectFill
    case .contain:
      return .resizeAspect
    }
  }
  
  private func changePlaybackQuality(_ url: URL) {
    let currentTime = player?.currentItem?.currentTime() ?? CMTime.zero
    let asset = AVURLAsset(url: url)
    let newPlayerItem = AVPlayerItem(asset: asset)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [self] in
      player?.replaceCurrentItem(with: newPlayerItem)
      player?.seek(to: currentTime)
      
      newPlayerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
      var playerItemStatusObservation: NSKeyValueObservation?
      playerItemStatusObservation = newPlayerItem.observe(\.status, options: [.new]) { [weak self] (item, _) in
        guard item.status == .readyToPlay else {
          self?.onError?(extractPlayerErrors(item))
          return
        }
        
        self?.loading = false
        playerItemStatusObservation?.invalidate()
      }
    })
  }
  
  private func onLoadingManager(hideLoading: Bool) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      if let duration = self.player?.currentItem?.duration, !duration.seconds.isNaN {
        self.loadingView.isHidden = hideLoading
        //            self._overlayView.isHidden = !hideLoading
      }
    }
    
  }
  
  private func verifyUrl(urlString: String?) throws -> URL {
    if let urlString = urlString, let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
      return url
    } else {
      throw VideoPlayerError.invalidURL
    }
  }
  
  private func urlOfCurrentPlayerItem(player : AVPlayer) -> URL? {
    return ((player.currentItem?.asset) as? AVURLAsset)?.url
  }
}
