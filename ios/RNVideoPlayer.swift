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
  
  private var _view: UIView!
  private var _subView: UIView!
  private var _overlayView: UIView!
  private var menuOptionsView = UIView()
  private var settingsStackView = UIStackView()
  private var loadingView = UIView()
  private var playBackSpeedModalView = UIView()
  private var qualityModalView = UIView()
  
  private var downloadView = UIView()
  private var qualityView = UIView()
  private var playbackSpeedView = UIView()
  
  private var imagePlayPause: String = ""
  private var url: URL?
  
  private var title = UILabel()
  private var playbackDuration = UILabel()
  private var playbackProgress = UILabel()
  
  private var seekSlider = UISlider(frame: .zero)
  
  private var playPauseButton = UIButton()
  private var forwardButton = UIButton()
  private var backwardButton = UIButton()
  private var settingsButton = UIButton()
  
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
  
  @objc var timeValueForChange: NSNumber? = 0
  @objc var fullScreen: Bool = false
  
  @objc var sliderProps: NSDictionary? = [:]
  @objc var forwardProps: NSDictionary? = [:]
  @objc var backwardProps: NSDictionary? = [:]
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
  @objc var source: String = "" {
    didSet {
      do {
        if source.isEmpty {
          return
        }
        
        let verificatedUrlString = try verifyUrl(urlString: source)
        player = AVPlayer(url: verificatedUrlString)
        player?.actionAtItemEnd = .none
        hasCalledSetup = true
        
        // Adicione um observador para o status do player
        player?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        player?.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        player?.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        player?.currentItem?.addObserver(self, forKeyPath: "playbackBufferFull", options: .new, context: nil)
        playerLayer = AVPlayerLayer(player: player)
        periodTimeObserver()
        
      } catch {
        self.onError?(["url": "Error on get url: error type is \(error)"])
      }
    }
  }
  
  @objc var videoTitle: String = ""
  
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
  
  override func layoutSubviews() {
    if hasCalledSetup {
      videoPlayerSubView()
      enableAudioSession()
    }
  }
  
  private func videoPlayerSubView() {
    guard let avPlayer = player else { return }
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
    _overlayView.backgroundColor = UIColor(white: 0, alpha: 0.4)
    _subView.addSubview(_overlayView)
    _overlayView.frame = _subView.frame
    _overlayView.isHidden = loading
    _overlayView.reactZIndex = 2
    
    let overlayControls = UIHostingController(rootView: OverlayManager(
      onTapBackward: {[self] in
        onTapBackwardTime()
      },
      onTapForward: { [self] in
        onTapFowardTime()
      },
      onTapFullScreen: { [self] in
        onToggleOrientation()
      },
      isFullScreen: fullScreen,
      onTapExit: onTapGoback,
      videoTile: videoTitle,
      onTapSettings: { [self] in
        onTapMenuOptions()
      }
    ))
    overlayControls.view.frame = _subView.frame
    _overlayView.addSubview(overlayControls.view)
    //    doubleTapVeiw.view.isHidden = loading
    overlayControls.view.backgroundColor = .clear
    
    // player
    onChangeOrientation(fullScreen)
    _subView.layer.addSublayer(playerLayer)
    //
    //    // PlayPause
    let playPause = PlayPauseLayoutManager(avPlayer, _overlayView)
    playPause.crateAndAdjustLayout(config: playPauseProps)
    playPauseButton = playPause.button()
    playPauseButton.addTarget(self, action: #selector(onTappedPlayPause), for: .touchUpInside)
    //
    // add forward button
    //    let forward = ForwardLayoutManager(_overlayView)
    //    forward.createAndAdjustLayout(config: forwardProps)
    //    forwardButton = forward.button()
    //    forwardButton.addTarget(self, action: #selector(onTapFowardTime), for: .touchUpInside)
    //
    //    // add backward button
    //    let backward = BackwardLayoutManager(_overlayView)
    //    backward.createAndAdjustLayout(config: backwardProps)
    //    backwardButton = backward.button()
    //    backwardButton.addTarget(self, action: #selector(onTapBackwardTime), for: .touchUpInside)
    
    let sizeLabelSeekSlider = calculateFrameSize(size10, variantPercent20)
    // seek slider label
    let trailingAnchor = calculateFrameSize(size50, variantPercent40)
    let labelDurationProps = labelDurationProps
    let labelDurationTextColor = labelDurationProps?["color"] as? String
    playbackDuration.textColor = transformStringIntoUIColor(color: labelDurationTextColor)
    playbackDuration.font = UIFont.systemFont(ofSize: sizeLabelSeekSlider)
    if playbackDuration.text == nil {
      playbackDuration.text = stringFromTimeInterval(interval: 0)
    }
    _overlayView.addSubview(playbackDuration)
    playbackDuration.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      playbackDuration.trailingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.trailingAnchor, constant: -trailingAnchor),
      playbackDuration.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.bottomAnchor, constant: -3)
    ])
    
    let labelProgressProps = labelProgressProps
    let labelProgressTextColor = labelProgressProps?["color"] as? String
    playbackProgress.textColor = transformStringIntoUIColor(color: labelProgressTextColor)
    playbackProgress.font = UIFont.systemFont(ofSize: sizeLabelSeekSlider)
    playbackProgress.frame = bounds
    if playbackProgress.text == nil {
      playbackProgress.text = stringFromTimeInterval(interval: 0)
    }
    playbackProgress.isHidden = true
    _overlayView.addSubview(playbackProgress)
    playbackProgress.translatesAutoresizingMaskIntoConstraints = false


//    title.text = videoTitle
//    title.numberOfLines = 2
//    
//    let titleSize = calculateFrameSize(size14, variantPercent10)
//    let titleColor = titleProps?["color"] as? String
//    
//    title.textColor = transformStringIntoUIColor(color: titleColor)
//    title.font = UIFont.systemFont(ofSize: titleSize)
//    //    title.isHidden = titleHidden ?? false
//    _overlayView.addSubview(title)
//    title.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//      title.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: size45),
//      title.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.topAnchor, constant: 5),
//      title.widthAnchor.constraint(lessThanOrEqualTo: _overlayView.safeAreaLayoutGuide.widthAnchor, multiplier: variantPercent60)
//    ])
    
    // seek slider
    _overlayView.addSubview(seekSlider)
    let seekTrailingAnchor = calculateFrameSize(size100, variantPercent30)
    configureThumb(sliderProps)
    seekSlider.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      seekSlider.leadingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.leadingAnchor),
      seekSlider.trailingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.trailingAnchor, constant: -seekTrailingAnchor),
      seekSlider.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.bottomAnchor, constant: -3),
    ])
    seekSlider.addTarget(self, action: #selector(self.seekSliderChanged(_:)), for: .valueChanged)
    
    
    // add more option
//    let settings = SettingsLayoutManager(_overlayView)
//    settings.createAndAdjustLayout(config: settingsSymbolProps)
//    settingsButton = settings.button()
//    settingsButton.transform = CGAffineTransform(rotationAngle: isRotated ? .pi : 0)
//    settingsButton.addTarget(self, action: #selector(onTapMenuOptions), for: .touchUpInside)
    
    settingsStackView.axis = .horizontal
    settingsStackView.spacing = calculateFrameSize(size10, variantPercent30)
    
    let trailingAnchorOptionsItemView = calculateFrameSize(size55, variantPercent20)
    _overlayView.addSubview(settingsStackView)
    settingsStackView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      settingsStackView.trailingAnchor.constraint(lessThanOrEqualTo: _overlayView.layoutMarginsGuide.trailingAnchor, constant: -trailingAnchorOptionsItemView),
      settingsStackView.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.topAnchor, constant: margin8)
    ])
    
    let loading = UIHostingController(rootView: LoadingManager(config: loadingProps))
    loading.view.frame = bounds
    loading.view.backgroundColor = .clear
    loadingView = loading.view
    loadingView.isHidden = !self.loading
    addSubview(loadingView)
    
    let speedRateModalTitle: String = speedRateModalProps?["title"] as? String ?? "Playback Speed"
    let speedRateModal = UIHostingController(
      rootView: ModalManager(
        onClose: { [self] in
          playBackSpeedModalView.removeFromSuperview()
          animatedPlayPause()
        },
        data: speedRateData,
        title: speedRateModalTitle,
        onSelected: { [self] item in
          player?.rate = item as! Float
        },
        onAppear: { [self] in
          player?.pause()
        },
        initialSelected: "Normal",
        isOpened: .constant(isOpenedModal)
      ))
    playBackSpeedModalView = speedRateModal.view
    playBackSpeedModalView.frame = frame
    playBackSpeedModalView.backgroundColor = UIColor(white: 0, alpha: 0.3)
    playBackSpeedModalView.isHidden = !isOpenedModal
    
    let qualityModalTitle: String = qualityModalProps?["title"] as? String ?? "Quality"
    let initialQualitySelected: String = qualityModalProps?["initialQualitySelected"] as! String
    let qualityData: [[String: String]] = qualityModalProps?["data"] as? [[String: String]] ?? [[:]]
    
    let qualityModal = UIHostingController(
      rootView: ModalManager(
        onClose: { [self] in
          qualityModalView.removeFromSuperview()
          animatedPlayPause()
        },
        data: qualityData,
        title: qualityModalTitle,
        onSelected: { [self] url in
          changePlaybackQuality(URL(string: url as! String)!)
          qualityModalView.removeFromSuperview()
          onLoadingManager(hideLoading: false)
        },
        onAppear: { [self] in
          player?.pause()
        },
        initialSelected: initialQualitySelected,
        isOpened: .constant(isOpenedModal)
      ))
    qualityModalView = qualityModal.view
    qualityModalView.frame = frame
    qualityModalView.backgroundColor = UIColor(white: 0, alpha: 0.3)
    qualityModalView.isHidden = !isOpenedModal
    
    let size = calculateFrameSize(size18, variantPercent30)
    let configQualitySymbolProps = settingsItemsSymbolProps?["quality"] as! NSDictionary
    let qualityD = UIHostingController(rootView: SettingsSymbolsLayoutManager(imageName: "chart.bar.fill", onTap: { [self] in
      onTapQuality()
    }))
    qualityD.view.backgroundColor = .clear
    qualityView = qualityD.view
    
    let configPlaybackSpeedSymProps = settingsItemsSymbolProps?["speedRate"] as! NSDictionary
    let playbackSpeedSymbol = UIHostingController(rootView: SettingsSymbolsLayoutManager(imageName: "timer", onTap: { [self] in
      onTapPlaybackSpeed()
    }))
    playbackSpeedSymbol.view.backgroundColor = .clear
    playbackSpeedView = playbackSpeedSymbol.view
    
    let configDownloadSymbolProps = settingsItemsSymbolProps?["download"] as! NSDictionary
    let downloadSymbol = UIHostingController(rootView: SettingsSymbolsLayoutManager(
      imageName: "arrow.down.to.line",
      onTap: { [self] in
        downloadVideo(
          from: urlOfCurrentlyPlayingInPlayer(player: player!)!,
          title: videoTitle,
          completion: { [self] (file, error) in
            if let filePath = file?.path {
              onVideoDownloaded?(["filePath": filePath as Any])
            } else {
              onError?(["download": error?.localizedDescription as Any])
            }
          })
      },
      config: configDownloadSymbolProps
    ))
    downloadSymbol.view.backgroundColor = .clear
    downloadView = downloadSymbol.view
    
    player?.currentItem?.addObserver(self, forKeyPath: "status", options: [], context: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem
    )
  }
  
  private func periodTimeObserver() {
    let interval = CMTime(value: 1, timescale: 2)
    timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      self?.updatePlayerTime()
    }
  }
  
  private func updatePlayerTime() {
    let time = videoTimerManager(avPlayer: player)
    let currentTime = time.getCurrentTimeInSeconds()
    let duration = time.getDurationTimeInSeconds()
    guard let currentItem = player?.currentItem else { return }
    
    let loadedTimeRanges = currentItem.loadedTimeRanges
    if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
      let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
      let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
      self.onVideoProgress?(["progress": currentTime, "bufferedDuration": bufferedStart + bufferedDuration])
    }
    
    playbackDuration.text = stringFromTimeInterval(interval: duration)
    playbackProgress.text = stringFromTimeInterval(interval: currentTime)
    
    if self.isSeeking == false {
      self.seekSlider.value = Float(currentTime/duration)
    }
  }
  
  
  private func removePeriodicTimeObserver() {
    guard let timeObserver = timeObserver else { return }
    player?.removeTimeObserver(timeObserver)
    self.timeObserver = nil
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
        loading = false
        onLoadingManager(hideLoading: true)
        onLoaded?(["duration": player.currentItem?.duration.seconds as Any])
        onReady?(["ready": true])
      } else if player.status == .failed {
        self.onError?(extractPlayerErrors(player.currentItem))
      } else if player.status == .unknown {
        self.onError?(extractPlayerErrors(player.currentItem))
      }
    }
  }
  
  @objc private func itemDidFinishPlaying(_ notification: Notification) {
    self.onCompleted?(["completed": true])
    self.removePeriodicTimeObserver()
  }
  
  @objc func seekSliderChanged(_ seekSlider: UISlider) {
    self.isSeeking = true
    playbackProgress.isHidden = false
    
    guard let duration = self.player?.currentItem?.duration else { return }
    let seconds : Float64 = Double(self.seekSlider.value) * CMTimeGetSeconds(duration)
    if seekSlider.currentThumbImage != nil {
      let thumbRect = seekSlider.thumbRect(forBounds: seekSlider.bounds, trackRect: seekSlider.trackRect(forBounds: seekSlider.bounds), value: seekSlider.value)
      let xPosition = thumbRect.origin.x
      
      playbackProgress.transform = CGAffineTransform(
        translationX: xPosition + seekSlider.frame.origin.x,
        y: seekSlider.frame.minY - size20
      )
    }
    
    if seconds.isNaN == false {
      let seekTime = CMTime(value: CMTimeValue(seconds), timescale: 1)
      self.player?.seek(to: seekTime, completionHandler: { [self] completed in
        if completed {
          self.isSeeking = false
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
            self.playbackProgress.isHidden = true
          })
        }
      })
    }
  }
  
  private func enableAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers, .allowAirPlay])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      onError?(["error": "cant able to enable audio background session \(error)"])
    }
  }
  
  //  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
  //    if let touch = touches.first {
  //      _subView.subviews.forEach {$0.isHidden = false}
  //    }
  //  }
  //
  //  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
  //    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: { [self] in
  //      _subView.subviews.forEach {$0.isHidden = true}
  //    })
  //  }
}

enum Resize: String {
  case contain, cover, stretch
}

enum VideoPlayerError: Error {
  case invalidURL
  case invalidPlayer
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
    animatedPlayPause()
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
    animatedPlayPause()
  }
  
  @objc private func onTapFowardTime() {
    let forward = videoTimerManager(avPlayer: player)
    forward.advance(Double(truncating: timeValueForChange!))
  }
  
  @objc private func onTapBackwardTime() {
    let backward = videoTimerManager(avPlayer: player)
    backward.advance(-Double(truncating: timeValueForChange!))
  }
  
  @objc private func onUpdatePlayerLayer(_ resizeMode: NSString) {
    let mode = Resize(rawValue: resizeMode as String)
    let videoGravity = videoGravity(mode!)
    
    DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
      self.playerLayer.videoGravity = videoGravity
    })
  }
  
  @objc private func onTapMenuOptions() {
    onSettingsTapped?([:])
    isRotated.toggle()
    
    let animation = CATransition()
    animation.type = .moveIn
    animation.subtype = .fromRight
    animation.duration = 0.1
    
    let rotationAngle: CGFloat = isRotated ? .pi : 0
    UIView.animate(withDuration: 0.2) { [self] in
      settingsButton.transform = CGAffineTransform(rotationAngle: rotationAngle)
    }

    if let downloadConfig = settingsItemsSymbolProps?["download"] as? [String: Any],
       let isHidden = downloadConfig["hidden"] as? Bool, !isHidden {
      settingsStackView.addArrangedSubview(downloadView)
    }
    
    
    if let speedRateConfig = settingsItemsSymbolProps?["speedRate"] as? [String: Any],
       let isHidden = speedRateConfig["hidden"] as? Bool, !isHidden {
      settingsStackView.addArrangedSubview(playbackSpeedView)
    }
    
    if let qualityConfig = settingsItemsSymbolProps?["quality"] as? [String: Any],
       let isHidden = qualityConfig["hidden"] as? Bool, !isHidden {
      settingsStackView.addArrangedSubview(qualityView)
    }
    
    downloadView.layer.add(animation, forKey: CATransitionType.push.rawValue)
    downloadView.isHidden = !isRotated
    
    playbackSpeedView.layer.add(animation, forKey: CATransitionType.push.rawValue)
    playbackSpeedView.isHidden = !isRotated
    
    qualityView.layer.add(animation, forKey: CATransitionType.push.rawValue)
    qualityView.isHidden = !isRotated
    
    settingsStackView.isHidden = !isRotated
    
    title.isHidden = isRotated
    
    if (!isRotated) {
      settingsStackView.arrangedSubviews.forEach {
        $0.removeFromSuperview()
      }
    }
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
    qualityModalView.isHidden = false
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
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
      player?.replaceCurrentItem(with: newPlayerItem)
      newPlayerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
      
      var playerItemStatusObservation: NSKeyValueObservation?
      playerItemStatusObservation = newPlayerItem.observe(\.status, options: [.new]) { [weak self] (item, _) in
        guard item.status == .readyToPlay else {
          self?.onError?(extractPlayerErrors(item))
          return
        }
        
        
        self?.player?.seek(to: currentTime)
        self?.onLoadingManager(hideLoading: true)
        self?.player?.play()
        self?.animatedPlayPause()
        playerItemStatusObservation?.invalidate()
      }
    })
  }
  
  private func animatedPlayPause() {
    playPauseButton.setImage(UIImage(systemName: player?.rate == 0 ? "play.fill" : "pause"), for: .normal)
  }
  
  private func onLoadingManager(hideLoading: Bool) {
    loadingView.isHidden = hideLoading
    _overlayView.isHidden = !hideLoading
    //    doubleTapVeiw.view.isHidden = !hideLoading
  }
  
  private func verifyUrl(urlString: String?) throws -> URL {
    if let urlString = urlString, let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
      return url
    } else {
      throw VideoPlayerError.invalidURL
    }
  }
  
  func urlOfCurrentlyPlayingInPlayer(player : AVPlayer) -> URL? {
    return ((player.currentItem?.asset) as? AVURLAsset)?.url
  }
}
