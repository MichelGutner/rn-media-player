import AVKit
import UIKit
import React
import AVFoundation

@objc(RNVideoPlayer)
class RNVideoPlayer: RCTViewManager {
  @objc override func view() -> (RNVideoPlayerView) {
    return RNVideoPlayerView()
  }
  
  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}

class RNVideoPlayerView: UIView, UIGestureRecognizerDelegate {
  private var viewControlls: UIView!
  private var loadingView = UIView()
  
  private var circleImage: UIImage!
  
  private var url: URL?
  
  private var labelCurrentTime: UILabel! = UILabel(frame: UIScreen.main.bounds)
  
  private var seekSlider: UISlider! = UISlider(frame:CGRect(x: 0, y:UIScreen.main.bounds.height - 60, width:UIScreen.main.bounds.width, height:10))
  
  private var playPauseCAShapeLayer = CAShapeLayer()
  private var fullScreenCAShapeLayer = CAShapeLayer()
  
  private var playPauseUIView = UIButton()
  private var forwardButton = UIButton()
  private var backwardButton = UIButton()
  private var fullScreenUIButton = UIButton()
  private var moreOptionsUIButton = UIButton()
  
  private var videoTimeForChange: Double?
  private var playerLayer: AVPlayerLayer!
  
  private var stringHandler = StringHandler()
  private var _shapeLayer = CustomCAShapeLayers()
  
  private var defaultControllerSize = CGFloat(80)
  
  
  private var hasCalledSetup = false
  private var player: AVPlayer?
  private var timeObserver: Any?

  
  @objc var onVideoProgress: RCTBubblingEventBlock?
  @objc var onLoaded: RCTBubblingEventBlock?
  @objc var onCompleted: RCTBubblingEventBlock?
  @objc var onMoreOptions: RCTDirectEventBlock?
  
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
      print("ERROR")
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
      setupVideoPlayer(source)
    }
  }
  
  @objc var fullScreen: Bool = false {
    didSet {
      self.onToggleOrientation()
    }
  }
  
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
  
  private func setupVideoPlayer(_ source: String) {
    guard let url = URL(string: source) else { return }
    if player == nil {
      player = AVPlayer(url: url)
      
      player?.actionAtItemEnd = .none
      hasCalledSetup = true
    }
    periodTimeObserver()
  }
  
  override func layoutSubviews() {
    if hasCalledSetup {
      videoPlayerSubView()
      enableAudioSession()
    }
  }
  
  private func videoPlayerSubView() {
    guard let avPlayer = player else { return }
    playerLayer = AVPlayerLayer(player: avPlayer)

    // View
    viewControlls = UIView()
    viewControlls.backgroundColor = .black
    viewControlls.frame = bounds
    addSubview(viewControlls)
    addSubview(loadingView)
    
    Loading(loadingView).showLoading()
    loadingView.frame.origin =  viewControlls.center
    // player
    onChangeDeviceOrientation()
    
    viewControlls.layer.addSublayer(playerLayer)
    
    // PlayPause
    viewControlls.addSubview(playPauseUIView)
    playPauseUIView.frame = CGRect(
      x: viewControlls.bounds.midX - (defaultControllerSize/2),
      y: viewControlls.bounds.midY - (defaultControllerSize/2),
      width: defaultControllerSize,
      height: defaultControllerSize
    )
    
    playPauseUIView.addTarget(self, action: #selector(onTappedPlayPause), for: .touchUpInside)
    
    
    
    // add forward button
    forwardButton.frame = CGRect(
      origin: CGPoint(
        x: viewControlls.frame.midX + (viewControlls.frame.midX * 0.3),
        y: playPauseUIView.frame.minY),
      size: playPauseUIView.frame.size
    )
    
    let forwardSvgLayer = _shapeLayer.createForwardShapeLayer(timeValueForChange!)
    forwardSvgLayer.position = CGPoint(
      x: forwardButton.bounds.midX + forwardSvgLayer.bounds.width / 2,
      y: forwardButton.bounds.midY + forwardSvgLayer.bounds.height / 2
    )
    
    forwardButton.layer.addSublayer(forwardSvgLayer)
    forwardButton.addTarget(self, action: #selector(fowardTime), for: .touchUpInside)
    
    viewControlls.addSubview(forwardButton)
    
    // add backward button
    backwardButton.frame = CGRect(
      origin: CGPoint(
        x: (viewControlls.frame.midX - playPauseUIView.frame.width) - (viewControlls.frame.midX * 0.3),
        y: playPauseUIView.frame.minY
      ),
      size: playPauseUIView.frame.size
    )
    let backwardSvgLayer = _shapeLayer.createBackwardShapeLayer(timeValueForChange!)
    
    backwardSvgLayer.position = CGPoint(
      x: backwardButton.bounds.midX + backwardSvgLayer.bounds.width / 2,
      y: backwardButton.bounds.midY + backwardSvgLayer.bounds.height / 2
    )
    
    backwardButton.layer.addSublayer(backwardSvgLayer)
    backwardButton.addTarget(self, action: #selector(backwardTime), for: .touchUpInside)
    
    viewControlls.addSubview(backwardButton)
    
    // seek slider monitoring label
    labelCurrentTime.textColor = .white
    labelCurrentTime.font = UIFont.systemFont(ofSize: 8)
    viewControlls.addSubview(labelCurrentTime)
    labelCurrentTime.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      labelCurrentTime.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 30),
      labelCurrentTime.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: viewControlls.layoutMarginsGuide.bottomAnchor, constant: -20)
    ])
    
    
    // seek slider
    seekSlider.addTarget(self, action: #selector(self.seekSliderChanged(_:)), for: .valueChanged)
    viewControlls.addSubview(seekSlider!)
    self.configureSeekSliderLayout()
    
    // add fullScreen
    fullScreenUIButton.frame = CGRect(
      x: viewControlls.bounds.maxX - (viewControlls.layoutMargins.right + 78),
      y: viewControlls.bounds.maxY - (viewControlls.layoutMargins.bottom + 45),
      width: 30,
      height: 30
    )
    let fullScreenLayer = _shapeLayer.createFullScreenShapeLayer()
    fullScreenLayer.position = CGPoint(x: fullScreenUIButton.bounds.minX + 10, y: fullScreenUIButton.bounds.minY + 10)
    if fullScreenCAShapeLayer.path == nil {
      fullScreenUIButton.layer.addSublayer(fullScreenLayer)
      fullScreenCAShapeLayer = fullScreenLayer
    }
    
    fullScreenUIButton.addTarget(self, action: #selector(onToggleOrientation), for: .touchUpInside)
    viewControlls.addSubview(fullScreenUIButton)
    
    // add more options
    moreOptionsUIButton.frame = CGRect(
      x: viewControlls.bounds.maxX - (viewControlls.layoutMargins.right + 48),
      y: viewControlls.bounds.maxY - (viewControlls.layoutMargins.bottom + 45),
      width: 30,
      height: 30
    )
    
    let moreOptionsLayer = _shapeLayer.createMoreOptionsShapeLayer()
    moreOptionsLayer.position = CGPoint(x: moreOptionsUIButton.bounds.minX + 15, y: moreOptionsUIButton.bounds.minY + 15)
    moreOptionsUIButton.layer.addSublayer(moreOptionsLayer)
    
    moreOptionsUIButton.addTarget(self, action: #selector(onTappedOnMoreOptions), for: .touchUpInside)
    viewControlls.addSubview(moreOptionsUIButton)
    
    
    player?.currentItem?.addObserver(self, forKeyPath: "status", options: [], context: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem
    )
  }
  
  private func periodTimeObserver() {
    let interval = CMTime(value: 1, timescale: 2)
    timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      guard let self = self else { return }
      self.onVideoProgress?(["progress": time.seconds])
      self.updatePlayerTime()
      
    }
  }
  
  private func updatePlayerTime() {
    guard let currentTitme = self.player?.currentTime() else {return}
    guard let duration = self.player?.currentItem?.duration else {return}
    let currenTimeInSecond = CMTimeGetSeconds(currentTitme)
    let durationTimeInSecond = CMTimeGetSeconds(duration)
    labelCurrentTime.text = (
      self.stringHandler.stringFromTimeInterval(
        interval: currenTimeInSecond) + "  " + self.stringHandler.stringFromTimeInterval(
          interval: (player?.currentItem?.duration.seconds)!
        )
    )
    if self.isThumbSeek == false {
      self.seekSlider.value = Float(currenTimeInSecond/durationTimeInSecond)
    }
    
  }
  
  private func removePeriodicTimeObserver() {
    guard let timeObserver = timeObserver else { return }
    player?.removeTimeObserver(timeObserver)
    self.timeObserver = nil
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == "status", let player = player {
      if player.status == .readyToPlay {
        self.onLoaded?(["duration": player.currentItem?.duration.seconds, "isReady": true])
        loadingView.removeFromSuperview()
        Loading(loadingView).hideLoading()
          let svgPauseLayer = _shapeLayer.createPauseShapeLayer()
          svgPauseLayer.frame.origin = CGPoint(x: playPauseUIView.bounds.midX, y: playPauseUIView.bounds.midY - svgPauseLayer.bounds.height / 2)
          
          if playPauseCAShapeLayer.path == nil {
            playPauseUIView.layer.addSublayer(svgPauseLayer)
            playPauseCAShapeLayer = svgPauseLayer
          }
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
        equalTo: layoutMarginsGuide.leadingAnchor, constant: 20
      ),
      seekSlider.trailingAnchor.constraint(
        equalTo: layoutMarginsGuide.trailingAnchor, constant: -20
      ),
      seekSlider.bottomAnchor.constraint(
        equalTo: viewControlls.layoutMarginsGuide.bottomAnchor
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
  
  //    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
  //      if let touch = touches.first {
  //        playerContainerView.subviews.forEach {$0.isHidden = false}
  //      }
  //    }
  //
  //    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
  //      DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: { [self] in
  //        playerContainerView.subviews.forEach {$0.isHidden = true}
  //      })
  //    }
  //
  
  // controllers
  @objc public func onToggleOrientation() {
    let fullsScreen = FullScreen(_window: window, parentView: fullScreenUIButton)
    fullsScreen.toggleFullScreen()
  }

  // native controllers
  @objc private func onTappedPlayPause() {
    let playPause = PlayPause(video: player, view: playPauseUIView, initialShapeLayer: playPauseCAShapeLayer)
    playPause.button()
  }
  
  @objc private func fowardTime() {
    let forward = Forward(player: player!, time: Double(truncating: timeValueForChange!))
    forward.button()
  }
  
  @objc private func backwardTime() {
    let backward = Backward(player: player!, time: Double(truncating: timeValueForChange!))
    backward.button()
  }
  
  private func onChangeDeviceOrientation() {
    guard let playerLayer = playerLayer else { return }
    let isLandscape: Bool
    
    if #available(iOS 13.0, *) {
      isLandscape = window?.windowScene?.interfaceOrientation.isLandscape == true
    } else {
      isLandscape = UIDevice.current.orientation.isLandscape
    }
    
    frame = isLandscape ? UIScreen.main.bounds : bounds
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
      playerLayer.videoGravity = isLandscape ? .resizeAspectFill : .resizeAspect
    })
    playerLayer.frame = isLandscape ? UIScreen.main.bounds : viewControlls.bounds
    fullScreenCAShapeLayer = isLandscape ? _shapeLayer.createExitFullScreenShapeLayer() : _shapeLayer.createFullScreenShapeLayer()
    
    let transition = CATransition()
    transition.type = .reveal
    transition.duration = 1.0
    
    fullScreenUIButton.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    fullScreenUIButton.layer.sublayers?.forEach { $0.add(transition, forKey: nil) }
    fullScreenUIButton.layer.addSublayer(fullScreenCAShapeLayer)
  }
  
  @objc private func onTappedOnMoreOptions() {
    self.onMoreOptions?(["tapped": true])
  }
}
