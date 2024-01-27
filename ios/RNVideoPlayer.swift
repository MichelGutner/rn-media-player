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
  private var isRotated = false
  private var isSeeking: Bool = false
  
  private var _view: UIView!
  private var _subView: UIView!
  private var _overlayView: UIView!
  private var menuOptionsView = UIView()
  private var optionsItemView = UIStackView()
  private var imagePlayPause: String = ""
  
  private var fullScreenImage: String!
  private var url: URL?
  
  private var title = UILabel()
  private var labelDuration = UILabel()
  private var labelProgress = UILabel()
  
  private var seekSlider = UISlider(frame: .zero)
  
  private var playPauseButton = UIButton()
  private var forwardButton = UIButton()
  private var backwardButton = UIButton()
  private var fullScreenButton = UIButton()
  private var menuOptionsButton = UIButton()
  private var goBackButton = UIButton()
  private var speedRateButton = UIButton()
  private var qualityButton = UIButton()
  
  private var videoTimeForChange: Double?
  private var playerLayer: AVPlayerLayer!
  
  private var hasCalledSetup = false
  private var player: AVPlayer?
  private var timeObserver: Any?
  
  @objc var onVideoProgress: RCTBubblingEventBlock?
  @objc var onLoaded: RCTBubblingEventBlock?
  @objc var onReady: RCTDirectEventBlock?
  @objc var onCompleted: RCTBubblingEventBlock?
  @objc var onMoreOptionsTapped: RCTDirectEventBlock?
  @objc var onFullScreenTapped: RCTDirectEventBlock?
  @objc var onError: RCTDirectEventBlock?
  @objc var onBuffer: RCTDirectEventBlock?
  @objc var onBufferCompleted: RCTDirectEventBlock?
  @objc var onGoBackTapped: RCTDirectEventBlock?
  @objc var timeValueForChange: NSNumber?
  @objc var fullScreen: Bool = false
  
  @objc var sliderProps: NSDictionary? = [:]
  @objc var forwardProps: NSDictionary? = [:]
  @objc var backwardProps: NSDictionary? = [:]
  @objc var playPauseProps: NSDictionary? = [:]
  @objc var labelProgressProps: NSDictionary? = [:]
  @objc var labelDurationProps: NSDictionary? = [:]
  @objc var menuOptionsProps: NSDictionary? = [:]
  @objc var fullScreenProps: NSDictionary? = [:]
  @objc var titleProps: NSDictionary? = [:]
  @objc var goBackProps: NSDictionary? = [:]
  @objc var menuOptionsItemProps: NSDictionary? = [:]
  
  // external controls
  @objc var source: String = "" {
    didSet {
      do {
        if source == "" {
          self.player?.replaceCurrentItem(with: nil)
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
        self.onError?(["error": "Error on get url: error type is \(error)"])
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
  
  
  // this function must be return a url error when trigger a invalid url
  func verifyUrl(urlString: String?) throws -> URL {
    if let urlString = urlString, let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
      return url
    } else {
      throw VideoPlayerError.invalidURL
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
    _overlayView.reactZIndex = 2
    
    // player
    onChangeOrientation(fullScreen)
    _subView.layer.addSublayer(playerLayer)
    
    // PlayPause
    let playPause = PlayPauseLayoutManager(avPlayer, _overlayView)
    playPause.crateAndAdjustLayout(config: playPauseProps)
    playPauseButton = playPause.button()
    playPauseButton.addTarget(self, action: #selector(onTappedPlayPause), for: .touchUpInside)
    
    // add forward button
    let forward = ForwardLayoutManager(_overlayView)
    forward.createAndAdjustLayout(config: forwardProps)
    forwardButton = forward.button()
    forwardButton.addTarget(self, action: #selector(fowardTime), for: .touchUpInside)
    
    // add backward button
    let backward = BackwardLayoutManager(_overlayView)
    backward.createAndAdjustLayout(config: backwardProps)
    backwardButton = backward.button()
    backwardButton.addTarget(self, action: #selector(backwardTime), for: .touchUpInside)
    
    let sizeLabelSeekSlider = calculateFrameSize(size10, variantPercent01)
    // seek slider label
    let trailingAnchor = calculateFrameSize(size50, variantPercent02)
    let labelDurationProps = labelDurationProps
    let labelDurationTextColor = labelDurationProps?["color"] as? String
    labelDuration.textColor = transformStringIntoUIColor(color: labelDurationTextColor)
    labelDuration.font = UIFont.systemFont(ofSize: sizeLabelSeekSlider)
    if labelDuration.text == nil {
      labelDuration.text = stringFromTimeInterval(interval: 0)
    }
    _overlayView.addSubview(labelDuration)
    labelDuration.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      labelDuration.trailingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.trailingAnchor, constant: -trailingAnchor),
      labelDuration.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.bottomAnchor, constant: -3)
    ])
    
    let labelProgressProps = labelProgressProps
    let labelProgressTextColor = labelProgressProps?["color"] as? String
    labelProgress.textColor = transformStringIntoUIColor(color: labelProgressTextColor)
    labelProgress.font = UIFont.systemFont(ofSize: sizeLabelSeekSlider)
    labelProgress.frame = bounds
    if labelProgress.text == nil {
      labelProgress.text = stringFromTimeInterval(interval: 0)
    }
    labelProgress.isHidden = true
    _overlayView.addSubview(labelProgress)
    labelProgress.translatesAutoresizingMaskIntoConstraints = false
    
    title.text = videoTitle
    title.numberOfLines = 2
    
    let titleSize = calculateFrameSize(size14, variantPercent01)
    let titleColor = titleProps?["color"] as? String
    
    title.textColor = transformStringIntoUIColor(color: titleColor)
    title.font = UIFont.systemFont(ofSize: titleSize)
    //    title.isHidden = titleHidden ?? false
    _overlayView.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      title.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: size45),
      title.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.topAnchor, constant: margin8),
      title.widthAnchor.constraint(lessThanOrEqualTo: _overlayView.safeAreaLayoutGuide.widthAnchor, multiplier: variantPercent06)
    ])
    
    let goBack = GoBackLayoutManager(_overlayView)
    goBack.createAndAdjustLayout(config: goBackProps)
    goBackButton = goBack.button()
    goBackButton.addTarget(self, action: #selector(onTappedGoback), for: .touchUpInside)
    
    // seek slider
    _overlayView.addSubview(seekSlider)
    let seekTrailingAnchor = calculateFrameSize(size80, variantPercent02)
    configureThumb(sliderProps)
    seekSlider.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      seekSlider.leadingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.leadingAnchor),
      seekSlider.trailingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.trailingAnchor, constant: -seekTrailingAnchor),
      seekSlider.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.bottomAnchor, constant: -3),
    ])
    seekSlider.addTarget(self, action: #selector(self.seekSliderChanged(_:)), for: .valueChanged)
    
    let fullScreen = FullScreenLayoutManager(_overlayView)
    fullScreen.createAndAdjustLayout(config: fullScreenProps)
    fullScreenButton = fullScreen.button()
    fullScreenButton.setBackgroundImage(UIImage(systemName: fullScreenImage ?? "arrow.up.left.and.arrow.down.right"), for: .normal)
    fullScreenButton.addTarget(self, action: #selector(onToggleOrientation), for: .touchUpInside)
    
    
    // add more option
    let menuOptions = MenuOptionsLayoutManager(_overlayView)
    menuOptions.createAndAdjustLayout(config: menuOptionsProps)
    menuOptionsButton = menuOptions.button()
    menuOptionsButton.transform = CGAffineTransform(rotationAngle: isRotated ? .pi : 0)
    menuOptionsButton.addTarget(self, action: #selector(onTapMenuOptions), for: .touchUpInside)
    
    
    let speedRate = SpeedRateLayoutManager(optionsItemView)
    speedRate.createAndAdjustLayout()
    speedRateButton = speedRate.button()
    
    let quality = QualityLayoutManager(optionsItemView)
    quality.createAndAdjustLayout()
    qualityButton = quality.button()
  
    optionsItemView.axis = .horizontal
    optionsItemView.spacing = spacing20

    // Create a spacer view to add space between buttons
    let trailingAnchorOptionsItemView = calculateFrameSize(size60, variantPercent02)
    
    _overlayView.addSubview(optionsItemView)
    optionsItemView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      optionsItemView.trailingAnchor.constraint(lessThanOrEqualTo: _overlayView.layoutMarginsGuide.trailingAnchor, constant: -trailingAnchorOptionsItemView),
      optionsItemView.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.topAnchor, constant: margin8)
    ])

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
    
    labelDuration.text = (stringFromTimeInterval(interval: duration))
    labelProgress.text = (stringFromTimeInterval(interval: currentTime))
    
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
        onLoaded?(["duration": player.currentItem?.duration.seconds as Any])
        onReady?(["ready": true])
      } else if player.status == .failed {
        onError?(["error": "Failed to load video \(player.status)"])
      } else if player.status == .unknown {
        onError?(["error": "Unknown to load video \(player.status)"])
      }
    }
  }
  
  @objc private func itemDidFinishPlaying(_ notification: Notification) {
    self.onCompleted?(["completed": true])
    self.removePeriodicTimeObserver()
  }
  
  @objc private func onPaused(_ paused: Bool) {
    if paused {
      player?.pause()
    } else {
      player?.play()
    }
  }
  
  @objc func seekSliderChanged(_ seekSlider: UISlider) {
    self.isSeeking = true
    labelProgress.isHidden = false
    
    guard let duration = self.player?.currentItem?.duration else { return }
    let seconds : Float64 = Double(self.seekSlider.value) * CMTimeGetSeconds(duration)
    if seekSlider.currentThumbImage != nil {
      let thumbRect = seekSlider.thumbRect(forBounds: seekSlider.bounds, trackRect: seekSlider.trackRect(forBounds: seekSlider.bounds), value: seekSlider.value)
      let xPosition = thumbRect.origin.x
      
      labelProgress.transform = CGAffineTransform(
        translationX: xPosition + seekSlider.frame.origin.x,
        y: seekSlider.frame.minY - size20
      )
    } else {
      print("No thumb image available")
    }

    if seconds.isNaN == false {
      let seekTime = CMTime(value: CMTimeValue(seconds), timescale: 1)
      self.player?.seek(to: seekTime, completionHandler: { [self] completed in
        if completed {
          self.isSeeking = false
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.labelProgress.isHidden = true
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
      print("cant able to enable audio background session", error)
    }
  }
  
  //      override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
  //        if let touch = touches.first {
  //          _subView.subviews.forEach {$0.isHidden = false}
  //        }
  //      }
  //
  //      override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
  //        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: { [self] in
  //          _subView.subviews.forEach {$0.isHidden = true}
  //        })
  //      }
  //
  
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
  @objc private func onTapMenuOptions() {
    onMoreOptionsTapped?([:])
    isRotated.toggle()
    
    let animation = CATransition()
    animation.type = .moveIn
    animation.subtype = .fromRight
    animation.duration = 0.1
    
    let rotationAngle: CGFloat = isRotated ? .pi : 0
    UIView.animate(withDuration: 0.2) { [weak self] in
      guard let self = self else { return }
      self.menuOptionsButton.transform = CGAffineTransform(rotationAngle: rotationAngle)
    }
    
    let spacerView = UIView()
    optionsItemView.addArrangedSubview(spacerView)
    
    if let speedRateConfig = menuOptionsItemProps?["speedRate"] as? [String: Any],
       let isDisabled = speedRateConfig["disabled"] as? Bool, !isDisabled {
      optionsItemView.addArrangedSubview(speedRateButton)
    }
    
    if let qualityConfig = menuOptionsItemProps?["quality"] as? [String: Any],
       let isDisabled = qualityConfig["disabled"] as? Bool, !isDisabled {
      optionsItemView.addArrangedSubview(qualityButton)
    }
    
    
    speedRateButton.layer.add(animation, forKey: CATransitionType.push.rawValue)
    self.speedRateButton.isHidden = !self.isRotated
    qualityButton.layer.add(animation, forKey: CATransitionType.push.rawValue)
    self.qualityButton.isHidden = !self.isRotated
    
    self.optionsItemView.isHidden = !self.isRotated
    
    self.title.isHidden = self.isRotated

    if (!isRotated) {
      optionsItemView.arrangedSubviews.forEach {
        $0.removeFromSuperview()
      }
    }
  }
  
  @objc private func onTappedGoback() {
    onGoBackTapped?([:])
  }
  
  @objc private func onToggleOrientation() {
    onFullScreenTapped?([:])
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
  
  @objc private func fowardTime() {
    let forward = videoTimerManager(avPlayer: player)
    forward.advance(Double(truncating: timeValueForChange!))
  }
  
  @objc private func backwardTime() {
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
}

// utillites methods
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
    playerLayer.frame = fullScreen ? bounds : bounds.inset(by: safeAreaInsets)
    
    fullScreenImage = fullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
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
  
  private func animatedPlayPause() {
    let animation = UIViewPropertyAnimator(duration: variantPercent02, curve: .easeInOut) { [self] in
      playPauseButton.transform = CGAffineTransform(scaleX: variantPercent08, y: variantPercent08)
      playPauseButton.setImage(UIImage(systemName: player?.rate == 0 ? "play.fill" : "pause"), for: .normal)
    }
    
    animation.addCompletion { _ in
      UIView.animate(withDuration: 0.2) {
        self.playPauseButton.transform = .identity
      }
    }
    animation.startAnimation()
  }
}
