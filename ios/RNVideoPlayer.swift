import AVKit
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
  private var _view: UIView!
  private var _subView: UIView!
  private var _overlayView: UIView!
  
  private var loadingView = UIView()
  
  private var circleImage: UIImage!
  private var fullScreenImage: String!
  
  
  private var url: URL?
  
  private var labelDuration = UILabel()
  private var labelProgress = UILabel()
  
  private var title = UILabel()
  
  private var seekSlider: UISlider! = UISlider(frame:CGRect(x: 0, y:UIScreen.main.bounds.height - 60, width:UIScreen.main.bounds.width, height:10))
  
  private var playPauseUIView = UIButton()
  private var forwardButton = UIButton()
  private var backwardButton = UIButton()
  private var fullScreenUIButton = UIButton()
  private var moreOptionsUIButton = UIButton()
  private var goBackButton = UIButton()
  
  private var videoTimeForChange: Double?
  private var playerLayer: AVPlayerLayer!
  
  private var stringHandler = StringHandler()
  
  private var controlSize = CGFloat(30)
  
  private var hasCalledSetup = false
  private var player: AVPlayer?
  private var timeObserver: Any?
  
  @objc var onVideoProgress: RCTBubblingEventBlock?
  @objc var onLoaded: RCTBubblingEventBlock?
  @objc var onCompleted: RCTBubblingEventBlock?
  @objc var onMoreOptionsTapped: RCTDirectEventBlock?
  @objc var onFullScreenTapped: RCTDirectEventBlock?
  @objc var onError: RCTDirectEventBlock?
  @objc var onBuffer: RCTDirectEventBlock?
  @objc var timeValueForChange: NSNumber?
  
  @objc var sliderProps: NSDictionary? = [:] {
    didSet {
      configureSlider()
    }
  }
  private func configureSlider() {
    guard let sliderProps = sliderProps,
          let minimumTrackColor = sliderProps["minimumTrackColor"] as? String,
          let maximumTrackColor = sliderProps["maximumTrackColor"] as? String,
          let thumbSize = sliderProps["thumbSize"] as? CGFloat,
          let thumbColor = sliderProps["thumbColor"] as? String else {
      return
    }
    
    seekSlider.minimumTrackTintColor = stringHandler.hexStringToUIColor(hexColor: minimumTrackColor)
    seekSlider.maximumTrackTintColor = stringHandler.hexStringToUIColor(hexColor: maximumTrackColor)
    
    circleImage = makeCircle(
      size: CGSize(width: thumbSize, height: thumbSize),
      backgroundColor: stringHandler.hexStringToUIColor(hexColor: thumbColor)
    )
    seekSlider.setThumbImage(circleImage, for: .normal)
    seekSlider.setThumbImage(circleImage, for: .highlighted)
  }
  
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
  
  @objc var videoTitle: String = "" {
    didSet {
      self.title.text = videoTitle
    }
  }
  
  @objc var fullScreen: Bool = false
  
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
  
  enum VideoPlayerError: Error {
    case invalidURL
    case invalidPlayer
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
    _overlayView.backgroundColor = UIColor(white: 0, alpha: 0.3)
    _subView.addSubview(_overlayView)
    _overlayView.frame = _subView.frame
    _overlayView.reactZIndex = 3
    _overlayView.addSubview(loadingView)
    
    // player
    onChangeOrientation(fullScreen)
    _subView.layer.addSublayer(playerLayer)
    
    // PlayPause
    let playPause = PlayPause(player, _overlayView)
    playPause.crateAndAdjustLayout()
    playPauseUIView = playPause.button()
    playPauseUIView.addTarget(self, action: #selector(onTappedPlayPause), for: .touchUpInside)
    
    // add forward button
    let forward = AdvanceVideoTimerComponent(_overlayView)
    forward.createAndAdjustLayout(isForward: true)
    forwardButton = forward.button()
    forwardButton.tintColor = .white
    forwardButton.addTarget(self, action: #selector(fowardTime), for: .touchUpInside)
    
    // add backward button
    let backward = AdvanceVideoTimerComponent(_overlayView)
    backward.createAndAdjustLayout(isForward: false)
    backwardButton = backward.button()
    backwardButton.tintColor = .white
    backwardButton.addTarget(self, action: #selector(backwardTime), for: .touchUpInside)
    
    // seek slider label
    let durationLabel = SeekLabel(_overlayView)
    durationLabel.createAndAdjustLayout(isDuration: true)
    labelDuration = durationLabel.label()
    
    
    let progressLabel = SeekLabel(_overlayView)
    progressLabel.createAndAdjustLayout(isDuration: false)
    labelProgress = progressLabel.label()
    
    
    title.textColor = .white
    title.font = UIFont.systemFont(ofSize: 18)
    _overlayView.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      title.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 30),
      title.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.topAnchor, constant: 4)
    ])
    
    goBackButton.tintColor = .white
    goBackButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
    _overlayView.addSubview(goBackButton)
    goBackButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      goBackButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 8),
      goBackButton.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.topAnchor, constant: 4)
    ])
    
    // seek slider
    seekSlider.addTarget(self, action: #selector(self.seekSliderChanged(_:)), for: .valueChanged)
    _overlayView.addSubview(seekSlider!)
    self.configureSeekSliderLayout()
    
    let fullScreen = FullScreen(_overlayView)
    fullScreen.createAndAdjustLayout()
    fullScreenUIButton = fullScreen.button()
    
    fullScreenUIButton.setImage(UIImage(systemName: fullScreenImage ?? "arrow.up.left.and.arrow.down.right"), for: .normal)
    
    fullScreenUIButton.addTarget(self, action: #selector(onToggleOrientation), for: .touchUpInside)
    
    
    // add more option
    moreOptionsUIButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
    moreOptionsUIButton.tintColor = .white
    moreOptionsUIButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 0.5)
    moreOptionsUIButton.addTarget(self, action: #selector(onTappedOnMoreOptions), for: .touchUpInside)
    _overlayView.addSubview(moreOptionsUIButton)
    moreOptionsUIButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      moreOptionsUIButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -60),
      moreOptionsUIButton.safeAreaLayoutGuide.topAnchor.constraint(equalTo: _overlayView.layoutMarginsGuide.topAnchor, constant: 4),
      moreOptionsUIButton.widthAnchor.constraint(equalToConstant: controlSize),
      moreOptionsUIButton.heightAnchor.constraint(equalToConstant: controlSize)
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
    
    labelDuration.text = (
      self.stringHandler.stringFromTimeInterval(
        interval: player?.currentItem?.duration.seconds ?? 0
      )
    )
    labelProgress.text = (
      self.stringHandler.stringFromTimeInterval(interval: currentTime )
    )
    if self.isThumbSeek == false {
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
        print("TESTING")
      case .none:
        break
      case .some(_):
        break
      }
    }
    if keyPath == "status", let player = player {
      if player.status == .readyToPlay {
        self.onLoaded?(["duration": player.currentItem?.duration.seconds, "isReady": true])
        playerLayer.frame = bounds
      } else if player.status == .failed {
        // Handle failure
        print("Failed to load video")
      } else if player.status == .unknown {
        // Handle unknown status
        print("Unknown status")
      }
    }
  }
  
  @objc private func itemDidFinishPlaying(_ notification: Notification) {
    self.onCompleted?(["completed": true])
    self.removePeriodicTimeObserver()
  }
  
  @objc private func onPaused(_ paused: Bool) {
    if player?.rate == 0
    {
      player?.play()
    } else {
      player?.pause()
    }
  }
  
  private var isThumbSeek: Bool = false
  @objc func seekSliderChanged(_ seekSlider: UISlider) {
    self.isThumbSeek = true
    guard let duration = self.player?.currentItem?.duration else { return }
    let seconds : Float64 = Double(self.seekSlider.value) * CMTimeGetSeconds(duration)
    
    if seconds.isNaN == false {
      let seekTime = CMTime(value: CMTimeValue(seconds), timescale: 1)
      self.player?.seek(to: seekTime, completionHandler: {completed in
        if completed {
          self.isThumbSeek = false
        }
      })
    }
  }
  
  private func configureSeekSliderLayout() {
    seekSlider.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      seekSlider.leadingAnchor.constraint(
        equalTo: layoutMarginsGuide.leadingAnchor, constant: 60
      ),
      seekSlider.trailingAnchor.constraint(
        equalTo: layoutMarginsGuide.trailingAnchor, constant: -60
      ),
      seekSlider.safeAreaLayoutGuide.bottomAnchor.constraint(
        equalTo: _subView.layoutMarginsGuide.bottomAnchor
      ),
    ])
  }
  
  @objc private func onChangeRate(_ rate: Float) {
    self.player?.rate = rate
  }
  
  private func makeCircle(size: CGSize, backgroundColor: UIColor) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(backgroundColor.cgColor)
    context?.setStrokeColor(UIColor.clear.cgColor)
    let bounds = CGRect(origin: .zero, size: size)
    context?.addEllipse(in: bounds)
    context?.drawPath(using: .fill)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
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
  
  // controllers
  @objc private func onToggleOrientation() {
    onFullScreenTapped?([:])
  }
  
  // native controllers
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
      playPauseUIView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
      playPauseUIView.setImage(UIImage(systemName: image), for: .normal)
    }
    
    animation.addCompletion { _ in
      UIView.animate(withDuration: 0.2) {
        self.playPauseUIView.transform = .identity
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
  
  private func onChangeOrientation(_ fullscreen: Bool) {
    guard let playerLayer = playerLayer else { return }
    playerLayer.frame = fullscreen ? UIScreen.main.bounds : bounds
    
    fullScreenImage = fullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
  }
  
  @objc private func onUpdatePlayerLayer(_ resizeMode: NSString) {
    let mode = Resize(rawValue: resizeMode as String)
    let videoGravity = videoGravity(mode!)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
      self.playerLayer.videoGravity = videoGravity
    })
  }
  
  @objc private func onTappedOnMoreOptions() {
    self.onMoreOptionsTapped?([:])
  }
  
}

enum Resize: String {
  case contain, cover, stretch
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
}
