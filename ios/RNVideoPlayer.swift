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
  private var optionsData: [HashableItem] = []
  private var initialQualitySelected: String = ""
  private var selectedItem: String = ""
  private var videoQualities: [VideoQualityData] = []
  
  private var _view: UIView!
  private var _subView: UIView!
  private var _overlayView: UIView!
  private var settingsStackView = UIStackView()
  private var loadingView = UIView()
  private var playBackSpeedModalView = UIView()
  private var qualityModalView = UIView()
  private var settingsModalView = UIView()
  private var downloadView = UIView()
  private var qualityView = UIView()
  private var playbackSpeedView = UIView()
  private var playPauseView = UIView()
  
  private var imagePlayPause: String = ""
  private var url: URL?
  
  private var title = UILabel()
  private var playbackDuration = UILabel()
  private var playbackProgress = UILabel()
  
  private var seekSlider = UISlider(frame: .zero)
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
  
  @objc var advanceValue: NSNumber? = 0
  @objc var suffixAdvanceValue: String? = "seconds"
  @objc var fullScreen: Bool = false
  @objc var thumbnailFramesSeconds: Float = 1.0
  
  @objc var sliderProps: NSDictionary? = [:]
  @objc var playPauseProps: NSDictionary? = [:]
  @objc var labelProgressProps: NSDictionary? = [:]
  @objc var labelDurationProps: NSDictionary? = [:]
  @objc var settingsSymbolProps: NSDictionary? = [:]
  @objc var fullScreenProps: NSDictionary? = [:]
  @objc var titleProps: NSDictionary? = [:]
  @objc var goBackProps: NSDictionary? = [:]
  @objc var loadingProps: NSDictionary? = [:]
  @objc var speedRateModalProps: NSDictionary? = [:]
  @objc var qualityModalProps: NSDictionary? = [:]
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
//        periodTimeObserver()
      } catch {
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

  override func layoutSubviews() {
      backgroundColor = .black
      guard let player = player else { return }
      let playbackUrl = source?["url"] as? String
      
    
    let playerView = UIHostingController(rootView: CustomView(playerUrl: playbackUrl!, player: player, thumbnails: thumbnailsFrames))
    playerView.view.frame = frame
    playerView.view.backgroundColor = .black
    addSubview(playerView.view)
        
    NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: .main) { [self] notification in
      DispatchQueue.main.async { [self] in
        NotificationCenter.default.post(name: Notification.Name("frames"), object: nil, userInfo: ["frames": thumbnailsFrames])
      }
    }
    
    if hasCalledSetup {
        enableAudioSession()
    }
  }

  // ...
  private func generatingThumbnailsFrames() {
    Task.detached { [self] in
        guard let asset = await player?.currentItem?.asset else { return }

        do {
          // Load the duration of the asset
          let totalDuration = asset.duration.seconds
          var framesTimes: [NSValue] = []
          print("total", totalDuration)

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
                // Handle the error
                return
              }
              
             
              print("dispatch", thumbnailsFrames.count, localFrames.count)
              DispatchQueue.main.async { [self] in
                let uiImage = UIImage(cgImage: cgImage)
                thumbnailsFrames.append(uiImage)
                
//                if thumbnailsFrames.count == localFrames.count {
                  NotificationCenter.default.post(name: Notification.Name("frames"), object: nil, userInfo: ["frames": thumbnailsFrames])
//                }
              }
              
            }
        }
      }
  }
  
  private func videoPlayerSubView() {
    guard let avPlayer = player else { return }
    let playbackTitle = source?["videoTitle"] as? String
    
    // View
    _view = UIView()
    _view.backgroundColor = .black
    _view.frame = bounds
    addSubview(_view)
    
    _subView = UIView()
    _subView.backgroundColor = .black
    _view.addSubview(_subView)
    _subView.frame = bounds
    
    _overlayView = UIView()
    _subView.addSubview(_overlayView)
    _overlayView.frame = _subView.frame
//    _overlayView.isHidden = loading
    _overlayView.reactZIndex = 2
    
    // MARK: - DoubleTap Controls
    
    let test = UIHostingController(rootView: ControlsManager(
      safeAreaInsets: safeAreaInsets,
      avPlayer: avPlayer,
      videoTitle: playbackTitle!,
      onTapGestureBackdrop: { [self] visible in
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [self] in
//          if !isSeeking {
//            seekSlider.isHidden = visible
//          }
//        })
        
      },
      onVideoProgress: { data in
        self.onVideoProgress?(data)
      },
      onSettingItemTapped: { item in
//        print("item", item)
      }, isLoading: self.loading,
      isFullScreen: fullScreen,
      onTapFullScreen: onToggleOrientation,
      configFullScreen: fullScreenProps,
      onTapForward: onTapFowardTime,
      onTapBackward: onTapBackwardTime,
      advanceValue: advanceValue as! Int,
      suffixAdvanceValue: suffixAdvanceValue!,
      isFinished: {
//        print("testing")
      },
      onTapSettings: onTapSettings,
      onTapExit: onTapGoback,
      onTapPlayPause: { [self] value in
        onPlayPause?(value) 
      },
      onAppearOverlay: { [self] in
        seekSlider.isHidden = false
      },
      onDisappearOverlay: { [self] in
        if !isSeeking {
          seekSlider.isHidden = true
        }
      }
    ))
    test.view.frame = _subView.frame
    test.view.backgroundColor = .clear
    _overlayView.addSubview(test.view)
    
    onChangeOrientation(fullScreen)
    _subView.layer.addSublayer(playerLayer)
    
    // seek slider label
//    let sizeLabelSeekSlider = calculateFrameSize(size10, variantPercent20)
//    let trailingAnchor = calculateFrameSize(size50, variantPercent40)
//    let labelDurationProps = labelDurationProps
//    let labelDurationTextColor = labelDurationProps?["color"] as? String
//    playbackDuration.textColor = transformStringIntoUIColor(color: labelDurationTextColor)
//    playbackDuration.font = UIFont.systemFont(ofSize: sizeLabelSeekSlider)
//    if playbackDuration.text == nil {
//      playbackDuration.text = stringFromTimeInterval(interval: 0)
//    }
//    _overlayView.addSubview(playbackDuration)
//    playbackDuration.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//      playbackDuration.trailingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.trailingAnchor, constant: -trailingAnchor),
//      playbackDuration.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.bottomAnchor, constant: -3)
//    ])
    
//    let labelProgressProps = labelProgressProps
//    let labelProgressTextColor = labelProgressProps?["color"] as? String
//    playbackProgress.textColor = transformStringIntoUIColor(color: labelProgressTextColor)
//    playbackProgress.font = UIFont.systemFont(ofSize: sizeLabelSeekSlider)
//    playbackProgress.frame = bounds
//    if playbackProgress.text == nil {
//      playbackProgress.text = stringFromTimeInterval(interval: 0)
//    }
//    playbackProgress.isHidden = true
//    _overlayView.addSubview(playbackProgress)
//    playbackProgress.translatesAutoresizingMaskIntoConstraints = false

    // seek slider
//    _overlayView.addSubview(seekSlider)
//    let seekTrailingAnchor = calculateFrameSize(size100, variantPercent30)
//    configureThumb(sliderProps)
//    seekSlider.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//      seekSlider.leadingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.leadingAnchor),
//      seekSlider.trailingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.trailingAnchor, constant: -seekTrailingAnchor),
//      seekSlider.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.bottomAnchor, constant: -10),
//    ])
//    seekSlider.addTarget(self, action: #selector(self.seekSliderChanged(_:)), for: .valueChanged)
    
//    settingsStackView.axis = .horizontal
//    settingsStackView.spacing = calculateFrameSize(size10, variantPercent30)
//
//    let trailingAnchorOptionsItemView = calculateFrameSize(size55, variantPercent20)
//    _overlayView.addSubview(settingsStackView)
//    settingsStackView.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//      settingsStackView.trailingAnchor.constraint(lessThanOrEqualTo: _overlayView.layoutMarginsGuide.trailingAnchor, constant: -trailingAnchorOptionsItemView),
//      settingsStackView.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.topAnchor, constant: margin8)
//    ])
    
    let loading = UIHostingController(rootView: LoadingManager(config: loadingProps))
    loading.view.frame = bounds
    loading.view.backgroundColor = .clear
    loadingView = loading.view
    loadingView.isHidden = !self.loading
//    addSubview(loadingView)
    
//    let speedRateModalTitle: String = speedRateModalProps?["title"] as? String ?? "Playback Speed"
//
//    let speedRateModal = UIHostingController(
//      rootView: ModalManager(
//        data: speedRateData,
//        title: speedRateModalTitle,
//        onSelected: { [self] item in
//          player?.rate = item as! Float
//          if playerStatus == .playing {
//            player?.play()
//          } else {
//            player?.pause()
//          }
//        },
//        onAppear: { [self] in
//          playerStatus = player?.timeControlStatus
//          if playerStatus == .playing {
//            player?.pause()
//          }
//        },
//        onDisappear: { [self] in
//          if playerStatus == .playing {
//            player?.play()
//          }
//        },
//        initialSelected: "Normal",
//        completionHandler: { [self] in
//          playBackSpeedModalView.removeFromSuperview()
//          animatedPlayPause()
//        }, children: (),
//        isOpened: .constant(isOpenedModal)
//      ))
//    playBackSpeedModalView = speedRateModal.view
//    playBackSpeedModalView.frame = frame
//    playBackSpeedModalView.backgroundColor = UIColor(white: 0, alpha: 0.3)
//    playBackSpeedModalView.isHidden = !isOpenedModal
//
    initialQualitySelected = qualityModalProps?["initialSelected"] as! String
    if let data = qualityModalProps?["data"] as? [[String: Any]] {
      videoQualities = data.map { VideoQualityData(dictionary: $0) }
    }

//    let qualityModal = UIHostingController(
//      rootView: ModalManager(
//        data: qualityData,
//        title: qualityModalTitle,
//        onSelected: { [self] url in
//          changePlaybackQuality(URL(string: url as! String)!)
//          qualityModalView.removeFromSuperview()
//          onLoadingManager(hideLoading: false)
//          if playerStatus == .playing {
//            player?.play()
//          }
//        },
//        onAppear: { [self] in
//          playerStatus = player?.timeControlStatus
//
//          if playerStatus == .playing {
//            player?.pause()
//          }
//        },
//        onDisappear: { [self] in
//          if playerStatus == .playing {
//            player?.play()
//          }
//        },
//        initialSelected: initialQualitySelected,
//        completionHandler: { [self] in
//          qualityModalView.removeFromSuperview()
//          animatedPlayPause()
//        }, children: (),
//        isOpened: .constant(isOpenedModal)
//      ))
//    qualityModalView = qualityModal.view
//    qualityModalView.frame = frame
//    qualityModalView.backgroundColor = UIColor(white: 0, alpha: 0.3)
//    qualityModalView.isHidden = !isOpenedModal
    
//    let configQualitySymbolProps = settingsItemsSymbolProps?["quality"] as! NSDictionary
//    let qualitySymbol = UIHostingController(rootView: SettingsSymbolManager(imageName: "chart.bar.fill", onTap: { [self] in
//      onTapQuality()
//    },config: configQualitySymbolProps))
//    qualitySymbol.view.backgroundColor = .clear
//    qualityView = qualitySymbol.view
//
//    let configPlaybackSpeedSymbolProps = settingsItemsSymbolProps?["speedRate"] as! NSDictionary
//    let playbackSpeedSymbol = UIHostingController(rootView: SettingsSymbolManager(imageName: "timer", onTap: { [self] in
//      onTapPlaybackSpeed()
//    }, config: configPlaybackSpeedSymbolProps))
//    playbackSpeedSymbol.view.backgroundColor = .clear
//    playbackSpeedView = playbackSpeedSymbol.view
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
    
    let modalSettings = UIHostingController(rootView: ModalManager(
      onModalAppear: {},
      onModalDisappear: {},
      onModalCompletion: { [self] in
        settingsOpened = false
        settingsModalView.removeFromSuperview()
      },
      modalContent: {
        SettingsModalView(
          settingsData: settingsData,
          onSettingSelected: { [self] item in
            settingsOpened = false
            settingsModalView.removeFromSuperview()
            let itemSelected = ESettingsOptions(rawValue: item)
            onSettingsItemSelected(itemSelected!)

            DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [self] in
              _overlayView.addSubview(qualityModalView)
              isOpenedModal = true
            })
          })
      })
    )
    modalSettings.view.frame = frame
    modalSettings.view.backgroundColor = UIColor(white: 0, alpha: 0.3)
    settingsModalView = modalSettings.view
    if settingsOpened {
      _overlayView.addSubview(settingsModalView)
    }

    
    let modalQuality = UIHostingController(rootView: ModalManager(
      onModalAppear: { [self] in
        playerStatus = player?.timeControlStatus
        if playerStatus == .playing {
          player?.pause()
        }
      },
      onModalDisappear: { [self] in
        if playerStatus == .playing {
          player?.play()
        }
      },
      onModalCompletion: { [self] in
        isOpenedModal = false
        qualityModalView.removeFromSuperview()
      },
      modalContent: { [self] in
        ModalOptionsView(
          data: videoQualities,
          onSelected: { [self] item in
            selectedItem = item.name
            changePlaybackQuality(URL(string: item.value)!)
            qualityModalView.removeFromSuperview()
            isOpenedModal = false
          },
          initialSelectedItem: initialQualitySelected,
          selectedItem: selectedItem
        )
      }
    ))
    modalQuality.view.frame = frame
    modalQuality.view.backgroundColor = UIColor(white: 0, alpha: 0.3)
    qualityModalView = modalQuality.view
    if isOpenedModal {
      _overlayView.addSubview(qualityModalView)
    }
    
    
    
    player?.currentItem?.addObserver(self, forKeyPath: "status", options: [], context: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem
    )
  }
  
  private func onSettingsItemSelected(_ item: ESettingsOptions) {
    switch(item) {
    case .quality:
//      optionsData = qualityOptionsData.reversed()
      return
    case .playbackSpeed:
      optionsData = playbackSpeedData
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
  
  @objc private func onTapFowardTime(_ advancedValue: Int) {
    let forward = videoTimerManager(avPlayer: player)
    forward.advance(Double(truncating: advanceValue!))
  }
  
  @objc private func onTapBackwardTime(_ advancedValue: Int) {
    let backward = videoTimerManager(avPlayer: player)
    backward.advance(-Double(truncating: advanceValue!))
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
    _overlayView.addSubview(settingsModalView)
  }
  
  @objc private func onTapGoback() {
    onGoBackTapped?([:])
  }
  
  @objc private func onToggleOrientation() {
    onFullScreenTapped?([:])
  }
  
  @objc private func onTapPlaybackSpeed() {
    isOpenedModal = true
    playBackSpeedModalView.isHidden = false
    _overlayView.addSubview(playBackSpeedModalView)
  }
  
  @objc private func onTapQuality() {
    isOpenedModal = true
    qualityView.isHidden = false
    _overlayView.addSubview(qualityModalView)
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
    playerLayer.frame = fullScreen ? bounds : _overlayView.bounds.inset(by: safeAreaInsets)
  }
  
  private func configureThumb(_ config: NSDictionary?) {
    let minimumTrackColor = config?["minimumTrackColor"] as? String
    let maximumTrackColor = config?["maximumTrackColor"] as? String
    let thumbSize = config?["thumbSize"] as? CGFloat
    let thumbColor = config?["thumbColor"] as? String
    
    seekSlider.minimumTrackTintColor = transformStringIntoUIColor(color: minimumTrackColor)
    seekSlider.maximumTrackTintColor = transformStringIntoUIColor(color: maximumTrackColor)
    
    let circleImage = createCircleImage(
      size: CGSize(width: thumbSize ?? size20, height: thumbSize ?? size20),
      backgroundColor: transformStringIntoUIColor(color: thumbColor)
    )
    seekSlider.setThumbImage(circleImage, for: .normal)
    seekSlider.setThumbImage(circleImage, for: .highlighted)
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
            self._overlayView.isHidden = !hideLoading
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
  
  private func urlOfCurrentlyPlayingInPlayer(player : AVPlayer) -> URL? {
    return ((player.currentItem?.asset) as? AVURLAsset)?.url
  }
}
