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
  private var playerIsFinished = false
  private var playerStatus: AVPlayer.TimeControlStatus?
  
  private var settingsOpened = false
  private var optionsData: [OptionSelection] = []
  
  private var initialQualitySelected = ""
  private var initialSpeedSelected = ""
  private var selectedQuality: String = ""
  private var selectedSpeed: String = ""
  
  private var videoQualities: [OptionSelection] = []
  private var videoSpeeds: [OptionSelection] = []
  
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
  @objc var settingsItemsSymbolProps: NSDictionary? = [:]
  
  // external controls
  @objc var source: NSDictionary? = [:] {
    didSet {
      do {
        let playbackUrl = source?["url"] as? String
        let playbackTitle = source?["videoTitle"] as? String
        
        let verificatedUrlString = try verifyUrl(urlString: playbackUrl)
        player = AVPlayer(url: verificatedUrlString)
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
  
  private var observer = PlayerObserver()
  
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
  
  @objc var resizeMode: NSString = "contain" {
    didSet {
      self.onUpdatePlayerLayer(resizeMode)
    }
  }
  
  @objc var startTime: Float = 0.0 {
    didSet {
      player?
        .currentItem?.seek(
          to: CMTime(seconds: Double(startTime), preferredTimescale: 1),
          completionHandler: nil
        )
    }
  }
  
  private var isFullScreen = false
  private var videoPlayerView = UIView()
  private var openedOptionsQualities: Bool = false
  private var openedOptionsSpeed: Bool = false

  @objc func toggleFullScreen(_ fullScreen: Bool) {
    if fullScreen {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: { [self] in
        videoPlayerView.removeFromSuperview()
        
        videoPlayerView.frame = UIScreen.main.bounds
        superview?.addSubview(videoPlayerView)
      })
    } else {
      videoPlayerView.removeFromSuperview()
      videoPlayerView.frame = frame
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
      videoQualities = qualitiesData.map { OptionSelection(dictionary: $0) }
    }
    
    if let speedsData = speeds?["data"] as? [[String: Any]] {
      videoSpeeds = speedsData.map { OptionSelection(dictionary: $0) }
    }
    
      let playerView = UIHostingController(
          rootView: CustomView(
              player: player,
              thumbnails: thumbnailsFrames,
              onTapFullScreenControl: { [self] state in
                  toggleFullScreen(state)
              },
              isFullScreen: isFullScreen,
              onTapSettingsControl: onTapSettings,
              videoQualities: videoQualities,
              initialQualitySelected: initialQualitySelected,
              videoSpeeds: videoSpeeds,
              initialSpeedSelected: initialSpeedSelected,
              selectedQuality: selectedQuality,
              selectedSpeed: selectedSpeed,
              settingsModalOpened: settingsOpened,
              openedOptionsQualities: openedOptionsQualities,
              openedOptionsSpeed: openedOptionsSpeed
          )
      )
    videoPlayerView = playerView.view
    videoPlayerView.backgroundColor = .black
    
    if videoPlayerView.frame == .zero {
      videoPlayerView.frame = frame
      superview?.addSubview(playerView.view)
    }
    

      
    NotificationCenter.default.addObserver(forName: Notification.Name("modal"), object: nil, queue: .main) { [self] modalNotification in
      if let optionsQualitySelected = (modalNotification.userInfo?["optionsQualitySelected"] as? String) {
        self.selectedQuality = optionsQualitySelected
      }
      
      if let optionsSpeedSelected = (modalNotification.userInfo?["optionsSpeedSelected"] as? String) {
        self.selectedSpeed = optionsSpeedSelected
      }
      
      if let openedModal = (modalNotification.userInfo?["opened"] as? Bool) {
        self.settingsOpened = openedModal
      }
      
      if let openedOptionsSpeed = (modalNotification.userInfo?["\(ESettingsOptions.speeds)Opened"] as? Bool) {
        print("opened \(openedOptionsSpeed)")
        self.openedOptionsSpeed = openedOptionsSpeed
      }
      
      if let openedOptionsQualities = (modalNotification.userInfo?["\(ESettingsOptions.qualities)Opened"] as? Bool) {
        self.openedOptionsQualities = openedOptionsQualities
      }
      
    }
    
    NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: .main) { [self] notification in
      DispatchQueue.main.async { [self] in
        NotificationCenter.default.post(name: Notification.Name("frames"), object: nil, userInfo: ["frames": thumbnailsFrames])
      }
    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    
    if hasCalledSetup {
      enableAudioSession()
      videoPlayerSubView()
    }
  }

  @objc private func orientationDidChange() {
    let currentOrientation = UIDevice.current.orientation
    let userInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    videoPlayerView.removeFromSuperview()
    
    if currentOrientation == .portrait || currentOrientation == .portraitUpsideDown {
      DispatchQueue.main.asyncAfter(deadline: .now()) { [self] in
        toggleFullScreen(false)
      }
    } else {
      if enterInFullScreenWhenDeviceRotated && userInterfaceIdiom != .pad {
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
//    let test = UIHostingController(rootView: ControlsManager(
//      safeAreaInsets: safeAreaInsets,
//      avPlayer: avPlayer,
//      videoTitle: playbackTitle!,
//      onTapGestureBackdrop: { [self] visible in
////        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [self] in
////          if !isSeeking {
////            seekSlider.isHidden = visible
////          }
////        })
//
//      },
//      onVideoProgress: { data in
//        self.onVideoProgress?(data)
//      },
//      onSettingItemTapped: { item in
////        print("item", item)
//      }, isLoading: self.loading,
////      isFullScreen: fullScreen,
//      onTapFullScreen: onToggleOrientation,
//      configFullScreen: fullScreenProps,
//      onTapForward: onTapFowardTime,
//      onTapBackward: onTapBackwardTime,
//      advanceValue: advanceValue as! Int,
//      suffixAdvanceValue: suffixAdvanceValue!,
//      isFinished: {
////        print("testing")
//      },
//      onTapSettings: onTapSettings,
//      onTapExit: onTapGoback,
//      onTapPlayPause: { [self] value in
//        onPlayPause?(value)
//      },
//      onAppearOverlay: { [self] in
//        seekSlider.isHidden = false
//      },
//      onDisappearOverlay: { [self] in
//        if !isSeeking {
//          seekSlider.isHidden = true
//        }
//      }
//    ))
    
    let loading = UIHostingController(rootView: LoadingManager(config: loadingProps))
    loading.view.frame = bounds
    loading.view.backgroundColor = .clear
    loadingView = loading.view
    loadingView.isHidden = !self.loading
//

    
//
//    let downloadManager = DownloadManager()
//    let configDownloadSymbolProps = settingsItemsSymbolProps?["download"] as! NSDictionary
//    let downloadSymbol = UIHostingController(rootView: SettingsSymbolManager(
//      imageName: "arrow.down.to.line",
//      onTap: { [self] in
//          downloadManager.downloadVideo(
//          from: urlOfCurrentlyPlayingInPlayer(player: player!)!,
//          title: playbackTitle!,
//          onProgress: { progress in
//            print("progress percentage", progress)
//          },
//          completion: { [self] (file, error) in
//            if let filePath = file?.path {
//              onVideoDownloaded?(["filePath": filePath as Any])
//            } else {
//              onError?(["download": error?.localizedDescription as Any])
//            }
//          })
//      },
//      config: configDownloadSymbolProps
//    ))
//    downloadSymbol.view.backgroundColor = .clear
//    downloadView = downloadSymbol.view
    
//    let modalSettings = UIHostingController(rootView: ModalManager(
//      onModalAppear: {},
//      onModalDisappear: {},
//      onModalCompletion: { [self] in
//        settingsOpened = false
//        settingsModalView.removeFromSuperview()
//      },
//      modalContent: {
//        SettingsModalView(
//          settingsData: settingsData,
//          onSettingSelected: { [self] item in
//            settingsOpened = false
//            settingsModalView.removeFromSuperview()
//            let itemSelected = ESettingsOptions(rawValue: item)
//            onSettingsItemSelected(itemSelected!)
//
//            DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [self] in
//              superview?.addSubview(qualityModalView)
//              isOpenedModal = true
//            })
//          })
//      })
//    )
//    modalSettings.view.frame = UIScreen.main.bounds
//    modalSettings.view.backgroundColor = UIColor(white: 0, alpha: 0.3)
//    settingsModalView = modalSettings.view
//    if settingsOpened {
//      superview?.addSubview(settingsModalView)
//    }

    
//    let modalQuality = UIHostingController(rootView: ModalManager(
//      onModalAppear: { [self] in
//        playerStatus = player?.timeControlStatus
//        if playerStatus == .playing {
//          player?.pause()
//        }
//      },
//      onModalDisappear: { [self] in
//        if playerStatus == .playing {
//          player?.play()
//        }
//      },
//      onModalCompletion: { [self] in
//        isOpenedModal = false
//        qualityModalView.removeFromSuperview()
//      },
//      modalContent: { [self] in
//        ModalOptionsView(
//          data: videoQualities,
//          onSelected: { [self] item in
//            selectedItem = item.name
//            changePlaybackQuality(URL(string: item.value)!)
//            qualityModalView.removeFromSuperview()
//            isOpenedModal = false
//          },
//          initialSelectedItem: initialQualitySelected,
//          selectedItem: selectedItem
//        )
//      }
//    ))
//    modalQuality.view.frame = UIScreen.main.bounds
//    modalQuality.view.backgroundColor = UIColor(white: 0, alpha: 0.3)
//    qualityModalView = modalQuality.view
//    if isOpenedModal {
//      superview?.addSubview(qualityModalView)
//    }
  }
  
  private func onSettingsItemSelected(_ item: ESettingsOptions) {
    switch(item) {
    case .qualities:
      optionsData = videoQualities
      return
    case .speeds:
      optionsData = videoSpeeds
      initialQualitySelected = "Normal"
      return
    case .moreOptions:
      return print("more options clicked")
    }
  }
  
//  private func periodTimeObserver() {
//    let interval = CMTime(value: 1, timescale: 2)
//    timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
//      self?.updatePlayerTime()
//    }
//  }
//
//  private func updatePlayerTime() {
//    let time = videoTimerManager(avPlayer: player)
//    let currentTime = time.getCurrentTimeInSeconds()
//    let duration = time.getDurationTimeInSeconds()
//    guard let currentItem = player?.currentItem else { return }
//
//    let loadedTimeRanges = currentItem.loadedTimeRanges
//    if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
//      let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
//      let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
//      self.onVideoProgress?(["progress": currentTime, "bufferedDuration": bufferedStart + bufferedDuration])
//    }
//
//    playbackDuration.text = stringFromTimeInterval(interval: duration)
//    playbackProgress.text = stringFromTimeInterval(interval: currentTime)
//
//    if self.isSeeking == false {
//      self.seekSlider.value = Float(currentTime/duration)
//    }
//  }
  
  
  private func removePeriodicTimeObserver() {
//    guard let timeObserver = timeObserver else { return }
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
    self.removePeriodicTimeObserver()
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
  @objc private func onTappedPlayPause() {
    if player?.rate == 0 {
      player?.play()
    } else {
      player?.pause()
    }
  }
  
  @objc private func onUpdatePlayerLayer(_ resizeMode: NSString) {
    let mode = Resize(rawValue: resizeMode as String)
    let videoGravity = videoGravity(mode!)
    
    DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
      self.playerLayer.videoGravity = videoGravity
    })
  }
  
  @objc private func onTapSettings() {
    onSettingsTapped?([:])
    settingsOpened = true
  }
  
  @objc private func onTapGoback() {
    onGoBackTapped?([:])
  }
  
  @objc private func onToggleOrientation() {
    onFullScreenTapped?([:])
  }
  
  @objc private func onTapPlaybackSpeed() {
    isOpenedModal = true
  }
  
  @objc private func onTapQuality() {
    isOpenedModal = true
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
  
  private func onChangeOrientation(_ fullscreen: Bool) {
    guard let playerLayer = playerLayer else { return }
//    playerLayer.frame = fullScreen ? bounds : _overlayView.bounds.inset(by: safeAreaInsets)
  }
  
//  private func configureThumb(_ config: NSDictionary?) {
//    let minimumTrackColor = config?["minimumTrackColor"] as? String
//    let maximumTrackColor = config?["maximumTrackColor"] as? String
//    let thumbSize = config?["thumbSize"] as? CGFloat
//    let thumbColor = config?["thumbColor"] as? String
//
//    seekSlider.minimumTrackTintColor = transformStringIntoUIColor(color: minimumTrackColor)
//    seekSlider.maximumTrackTintColor = transformStringIntoUIColor(color: maximumTrackColor)
//
//    let circleImage = createCircleImage(
//      size: CGSize(width: thumbSize ?? size20, height: thumbSize ?? size20),
//      backgroundColor: transformStringIntoUIColor(color: thumbColor)
//    )
//    seekSlider.setThumbImage(circleImage, for: .normal)
//    seekSlider.setThumbImage(circleImage, for: .highlighted)
//  }
  
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
