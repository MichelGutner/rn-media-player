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

class RNVideoPlayerViewController: UIViewController {
  
}

class RNVideoPlayerView: UIView, UIGestureRecognizerDelegate {
  private var fullScreenButtonLayer = UIButton()
  private var fullScreenLayers = CAShapeLayer()
  private var circleImage: UIImage!
  
  private var playPauseUIView = UIButton()
  private var playPauseCAShapeLayer = CAShapeLayer()
  
  private var forwardButton = UIButton()
  private var backwardButton = UIButton()
  private var fullScreenButton = UIButton()
  private var videoTimeForChange: Double?
  private var playerLayer: AVPlayerLayer!
  private var stringHandler = StringHandler()
  private var _shapeLayer = CAShapeLayers()

  private var controlSize = CGFloat(80)
  
  
  private var hasCalledSetup = false
  private var player: AVPlayer?
  private var timeObserver: Any?
  private var seekSlider: UISlider! = UISlider(frame:CGRect(x: 0, y:UIScreen.main.bounds.height - 60, width:UIScreen.main.bounds.width, height:10))
  private var playerContainerView: UIView!
  private var labelCurrentTime: UILabel! = UILabel(frame: UIScreen.main.bounds)
  
  @objc var onVideoProgress: RCTBubblingEventBlock?
  @objc var onLoaded: RCTBubblingEventBlock?
  @objc var onCompleted: RCTBubblingEventBlock?
  @objc var onDeviceOrientation: RCTBubblingEventBlock?
  
  @objc var timeValueForChange: NSNumber?
  
  @objc var sliderProps: NSDictionary? = [:] {
    didSet {
      if let sliderProps {
        seekSlider.minimumTrackTintColor = stringHandler.hexStringToUIColor(hexColor: sliderProps["minimumTrackColor"] as! String)
        seekSlider.maximumTrackTintColor = stringHandler.hexStringToUIColor(hexColor: sliderProps["maximumTrackColor"] as! String)
        self.circleImage = self.makeCircle(
          size: CGSize(
            width: sliderProps["thumbSize"] as? CGFloat ?? 20,
            height: sliderProps["thumbSize"] as? CGFloat ?? 20
          ),
          backgroundColor: stringHandler.hexStringToUIColor(hexColor: sliderProps["thumbColor"] as! String)
        )
      } else {
        print("ERROR")
      }
    }
  }
  
  
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
    if let url = URL(string: source) {
      player = AVPlayer(url: url)
      player?.actionAtItemEnd = .none
      hasCalledSetup = true
      periodTimeObserver()
    }
  }
  
  override func layoutSubviews() {
    if hasCalledSetup {
      videoPlayerSubView()
    }
  }
  
  private func videoPlayerSubView() {
    guard let avPlayer = player else { return }
    playerLayer = AVPlayerLayer(player: avPlayer)
    
    // View
    playerContainerView = UIView()
    playerContainerView.backgroundColor = .black
    playerContainerView.frame = bounds
    
    addSubview(playerContainerView)
    
    // player
    onChangeDeviceOrientation(playerLayer)
    
    playerContainerView.layer.addSublayer(playerLayer)
    
    // PlayPause
    playerContainerView.addSubview(playPauseUIView)
    playPauseUIView.frame = CGRect(
      x: playerContainerView.bounds.midX - (controlSize/2),
      y: playerContainerView.bounds.midY - (controlSize/2),
      width: controlSize,
      height: controlSize
    )
    
    let svgPauseLayer = _shapeLayer.pause()
    svgPauseLayer.frame.origin = CGPoint(x: playPauseUIView.bounds.midX, y: playPauseUIView.bounds.midY - svgPauseLayer.bounds.height / 2)
    
    if playPauseCAShapeLayer.path == nil {
      playPauseUIView.layer.addSublayer(svgPauseLayer)
      playPauseCAShapeLayer = svgPauseLayer
    }
    
    playPauseUIView.addTarget(self, action: #selector(onTappedPlayPause), for: .touchUpInside)
    
    
    
    // add forward button
    forwardButton.frame = CGRect(
      origin: CGPoint(
        x: playerContainerView.frame.midX + (playerContainerView.frame.midX * 0.3),
        y: playPauseUIView.frame.minY),
      size: CGSize(width: playPauseUIView.frame.width, height: playPauseUIView.frame.height)
    )
    
    let forwardSvgLayer = _shapeLayer.forward(timeValueForChange!)
    forwardSvgLayer.position = CGPoint(
      x: forwardButton.bounds.midX + forwardSvgLayer.bounds.width / 2,
      y: forwardButton.bounds.midY + forwardSvgLayer.bounds.height / 2
    )
    
    forwardButton.layer.addSublayer(forwardSvgLayer)
    forwardButton.addTarget(self, action: #selector(fowardTime), for: .touchUpInside)
    
    playerContainerView.addSubview(forwardButton)
    
    // add backward button
    backwardButton.frame = CGRect(
      origin: CGPoint(
        x: (playerContainerView.frame.midX - playPauseUIView.frame.width) - (playerContainerView.frame.midX * 0.3),
        y: playPauseUIView.frame.minY
      ),
      size: CGSize(width: playPauseUIView.frame.width, height: playPauseUIView.frame.height)
    )
    let backwardSvgLayer = _shapeLayer.backward(timeValueForChange!)
    
    backwardSvgLayer.position = CGPoint(
      x: forwardButton.bounds.midX + backwardSvgLayer.bounds.width / 2,
      y: forwardButton.bounds.midY + backwardSvgLayer.bounds.height / 2
    )
    
    backwardButton.layer.addSublayer(backwardSvgLayer)
    backwardButton.addTarget(self, action: #selector(backwardTime), for: .touchUpInside)
    
    playerContainerView.addSubview(backwardButton)
    
    // seek slider monitoring label
    labelCurrentTime.textColor = .white
    labelCurrentTime.font = UIFont.systemFont(ofSize: 8)
    playerContainerView.addSubview(labelCurrentTime)
    labelCurrentTime.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      labelCurrentTime.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 30),
      labelCurrentTime.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: playerContainerView.layoutMarginsGuide.bottomAnchor, constant: -20)
    ])
    
    
    // seek slider
    self.configureSliderProps()
    playerContainerView.addSubview(seekSlider!)
    self.configureSeekSliderLayout()
    
    // add fullScreen
    fullScreenButtonLayer.frame = CGRect(
      x: playerContainerView.bounds.maxX - (playerContainerView.layoutMargins.right + controlSize / 2),
      y: playerContainerView.bounds.maxY - (playerContainerView.layoutMargins.bottom + controlSize / 2),
      width: 22,
      height: 22
    )
    if fullScreenLayers.path == nil {
      fullScreenButtonLayer.layer.addSublayer(_shapeLayer.fullScreen())
    }
    fullScreenButtonLayer.addTarget(self, action: #selector(onToggleOrientation), for: .touchUpInside)
    playerContainerView.addSubview(fullScreenButtonLayer)
    
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
    if object as? AVPlayerItem == player?.currentItem, keyPath == "status" {
      if player?.currentItem?.status == .readyToPlay {
        self.onLoaded?(["duration": player?.currentItem?.duration.seconds, "isReady": true])
        self.enableAudioSession()
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
        equalTo: playerContainerView.layoutMarginsGuide.bottomAnchor
      ),
    ])
  }
  
  @objc private func onChangeRate(_ rate: Float) {
    self.player?.rate = rate
  }
  
  @objc private func configureSliderProps() {
    seekSlider.addTarget(self, action: #selector(self.seekSliderChanged(_:)), for: .valueChanged)
    seekSlider.setThumbImage(circleImage, for: .normal)
    seekSlider.setThumbImage(circleImage, for: .highlighted)
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
  
  @objc private func fowardTime() {
    let forward = Forward(player: player!, time: Double(truncating: timeValueForChange!))
    forward.button()
  }
  
  @objc private func backwardTime() {
    let backward = Backward(player: player!, time: Double(truncating: timeValueForChange!))
    backward.button()
  }
  
  
  @objc public func onToggleOrientation() {
    if #available(iOS 16.0, *) {
      if window?.windowScene?.interfaceOrientation.isPortrait == true {
        fullScreenLayers = _shapeLayer.exitFullScreen()
        window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
          print(error.localizedDescription)
        }
      } else {
        fullScreenLayers = _shapeLayer.fullScreen()
        window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
          print(error.localizedDescription)
        }
        
      }
    } else {
      if UIInterfaceOrientation.portrait == .portrait {
        let orientation = UIInterfaceOrientation.landscapeRight.rawValue
        fullScreenLayers = _shapeLayer.exitFullScreen()
        UIDevice.current.setValue(orientation, forKey: "orientation")
      } else {
        fullScreenLayers = _shapeLayer.fullScreen()
        let orientation = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(orientation, forKey: "orientation")
      }
    }
    let transition = CATransition()
    transition.type = .reveal
    transition.duration = 1.0
    
    fullScreenButtonLayer.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    fullScreenButtonLayer.layer.sublayers?.forEach{ $0.add(transition, forKey: nil)}
    fullScreenButtonLayer.layer.addSublayer(fullScreenLayers)
    
  }
  
  //  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
  //    if let touch = touches.first {
  //      playerContainerView.subviews.forEach {$0.isHidden = false}
  //    }
  //  }
  //
  //  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
  //    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: { [self] in
  //      playerContainerView.subviews.forEach {$0.isHidden = true}
  //    })
  //  }
  
  private func onChangeDeviceOrientation(_ layer: AVPlayerLayer) {
    if #available(iOS 13.0, *) {
      if window?.windowScene?.interfaceOrientation.isLandscape == true {
        frame = UIScreen.main.bounds
        layer.videoGravity = .resizeAspectFill
        playerLayer.frame = UIScreen.main.bounds
      } else {
        frame = bounds
        layer.videoGravity = .resizeAspect
        playerLayer.frame = playerContainerView.bounds
      }
    } else {
      if UIDevice.current.orientation.isLandscape {
        layer.videoGravity = .resizeAspectFill
      }
    }
  }
  
  @objc private func onTappedPlayPause() {
    let playPause = PlayPause(video: player, view: playPauseUIView, initialShapeLayer: playPauseCAShapeLayer)
    playPause.button()
  }
}
