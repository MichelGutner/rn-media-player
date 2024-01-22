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
  private var progress = 0.0
  private var thumbnailFrames: [UIImage] = []
  private var frameTimes: [CMTime] = []
  private var draggingImage: UIImage?
  private var isSeeking: Bool = false
  
  private var _view: UIView!
  private var _subView: UIView!
  private var _overlayView: UIView!
  private var SeekerThumbnailView = UIImageView()
  
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
    _overlayView.reactZIndex = 3
    
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
    
    let sizeLabelSeekSlider = calculateFrameSize(10, 0.1)
    // seek slider label
    let trailingAnchor = calculateFrameSize(70, 0.2)
    let labelDurationProps = labelDurationProps
    let labelDurationTextColor = labelDurationProps?["color"] as? String
    labelDuration.textColor = hexStringToUIColor(hexColor: labelDurationTextColor)
    labelDuration.font = UIFont.systemFont(ofSize: sizeLabelSeekSlider)
    if labelDuration.text == nil {
      labelDuration.text = stringFromTimeInterval(interval: 0)
    }
//    _overlayView.addSubview(labelDuration)
//    labelDuration.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//      labelDuration.trailingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.trailingAnchor, constant: -trailingAnchor),
//      labelDuration.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.bottomAnchor, constant: -3)
//    ])
    
//    let labelProgressProps = labelProgressProps
//    let labelProgressTextColor = labelProgressProps?["color"] as? String
//    labelProgress.textColor = hexStringToUIColor(hexColor: labelProgressTextColor)
//    labelProgress.font = UIFont.systemFont(ofSize: sizeLabelSeekSlider)
//    if labelProgress.text == nil {
//      labelProgress.text = stringFromTimeInterval(interval: 0)
//    }
//    _overlayView.addSubview(labelProgress)
//    labelProgress.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//      labelProgress.leadingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.leadingAnchor),
//      labelProgress.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.bottomAnchor, constant: -3)
//    ])
    
    title.text = videoTitle
    title.numberOfLines = 2
    
    let titleSize = calculateFrameSize(14, 0.1)
    let titleColor = titleProps?["color"] as? String
//    let titleHidden = titleProps?["hidden"] as? Bool
    
    title.textColor = hexStringToUIColor(hexColor: titleColor)
    title.font = UIFont.systemFont(ofSize: titleSize)
//    title.isHidden = titleHidden ?? false
    _overlayView.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      title.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 45),
      title.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.topAnchor),
      title.widthAnchor.constraint(lessThanOrEqualTo: _overlayView.safeAreaLayoutGuide.widthAnchor, multiplier: 0.3)
    ])
    
    let goBack = GoBackLayoutManager(_overlayView)
    goBack.createAndAdjustLayout(config: goBackProps)
    goBackButton = goBack.button()
    goBackButton.addTarget(self, action: #selector(onTappedGoback), for: .touchUpInside)
    
    // seek slider
    _overlayView.addSubview(seekSlider)
    let seekTrailingAnchor = calculateFrameSize(130, 0.2)
    configureThumb(sliderProps)
    seekSlider.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      seekSlider.leadingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.leadingAnchor),
      seekSlider.trailingAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.trailingAnchor),
      seekSlider.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.bottomAnchor, constant: -5),
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
    
    
    let speedRate = SpeedRateLayoutManager(_overlayView)
    speedRate.createAndAdjustLayout()
    speedRateButton = speedRate.button()
    speedRateButton.isHidden = !isRotated
    
    _overlayView.addSubview(SeekerThumbnailView)
    SeekerThumbnailView.backgroundColor = .black
//    let originSeekThumbnail = CGPoint(x: _overlayView.safeAreaLayoutGuide.layoutFrame.minX, y: _overlayView.safeAreaLayoutGuide.layoutFrame.midY)
    SeekerThumbnailView.frame.size = CGSize(width: bounds.width * 0.25, height: bounds.height * 0.25)
    SeekerThumbnailView.layer.opacity = isSeeking ? 1 : 0
    
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
    SeekerThumbnailView.layer.opacity = isSeeking ? 1 : 0
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
    self.progress = currentTime
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
        generateThumbnailFrames()
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
  
  @objc func generateThumbnailFrames() {
    Task.detached { [self] in
      guard let currentItem = await player?.currentItem else { return }
      let generator = AVAssetImageGenerator(asset: currentItem.asset)
      generator.appliesPreferredTrackTransform = true
      
      generator.maximumSize = .init(width: 175, height: 100)

      do {
        let totalDuration = currentItem.asset.duration.seconds
        
        for progress in stride(from: 0, to: 1, by: 0.001) {
          
          let time = CMTime(seconds: progress * totalDuration, preferredTimescale: 1000)
          await MainActor.run(body: {
//            if !frameTimes.contains(time) {
                frameTimes.append(time)
//            }
          })
        }
        
        await print(frameTimes.count)
        
        for time in await frameTimes {
          generator.generateCGImagesAsynchronously(forTimes: [time as NSValue]) { requestedTime, cgImage, actualTime, result, error in
            if let cgImage = cgImage {
              // Process the CGImage in the main thread
              DispatchQueue.main.async { [self] in
                thumbnailFrames.append(UIImage(cgImage: cgImage))
              }
            } else if let error = error {
              // Handle error
              print("Error: \(error)")
            }}
        }
      }
    }
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
    guard let duration = self.player?.currentItem?.duration else { return }
    let seconds : Float64 = Double(self.seekSlider.value) * CMTimeGetSeconds(duration)
    let dragIndex = Int(seconds / 0.01)
//    print("drag", Int(dragIndex / 100))
    var myIndex = Int(seconds / ((duration.seconds / duration.seconds) * 0.3))
    print("index", Int(myIndex))
//    frameTimes.forEach {
//      print("frames", $0.seconds)
//    }
    print("contain", frameTimes[myIndex].seconds)
    if thumbnailFrames.indices.contains(myIndex) {
      
      SeekerThumbnailView.image = thumbnailFrames[myIndex]
      if let thumbImage = seekSlider.currentThumbImage {
        let thumbRect = seekSlider.thumbRect(forBounds: seekSlider.bounds, trackRect: seekSlider.trackRect(forBounds: seekSlider.bounds), value: seekSlider.value)
        let xPosition = thumbRect.origin.x
//        SeekerThumbnailView.center = CGPoint(x: xPosition + seekSlider.frame.origin.x, y: seekSlider.frame.origin.y - 45)
        SeekerThumbnailView.transform = CGAffineTransform(translationX: xPosition, y: seekSlider.frame.minY - 120)
      } else {
          print("No thumb image available")
      }

    }
    if seconds.isNaN == false {
      let seekTime = CMTime(value: CMTimeValue(seconds), timescale: 1)
      print("seek", seekTime.seconds)
      self.player?.seek(to: seekTime, completionHandler: { [self] completed in
//        player?.play()
        if completed {
          self.isSeeking = false
        }
      })
    }
  }
  
  private func enableAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers, .allowAirPlay])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print(error)
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
    // Toggle the showMenuOptions variable
    
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
    speedRateButton.layer.add(animation, forKey: CATransitionType.push.rawValue)
    self.speedRateButton.isHidden = !self.isRotated
    self.title.isHidden = self.isRotated

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
    var image = ""
    if player?.rate == 0 {
      player?.play()
      image = "pause"
    } else {
      player?.pause()
      image = "play.fill"
    }
    
    let animation = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut) { [self] in
      playPauseButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
      playPauseButton.setImage(UIImage(systemName: image), for: .normal)
    }
    
    animation.addCompletion { _ in
      UIView.animate(withDuration: 0.2) {
        self.playPauseButton.transform = .identity
      }
    }
    animation.startAnimation()
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
    guard let sliderProps = config,
          let minimumTrackColor = sliderProps["minimumTrackColor"] as? String,
          let maximumTrackColor = sliderProps["maximumTrackColor"] as? String,
          let thumbSize = sliderProps["thumbSize"] as? CGFloat,
          let thumbColor = sliderProps["thumbColor"] as? String else {
      return
    }
    
    seekSlider.minimumTrackTintColor = hexStringToUIColor(hexColor: minimumTrackColor)
    seekSlider.maximumTrackTintColor = hexStringToUIColor(hexColor: maximumTrackColor)
    
    let circleImage = createCircle(
      size: CGSize(width: thumbSize, height: thumbSize),
      backgroundColor: hexStringToUIColor(hexColor: thumbColor)
    )
    seekSlider.setThumbImage(circleImage, for: .normal)
    seekSlider.setThumbImage(circleImage, for: .highlighted)
  }
}
