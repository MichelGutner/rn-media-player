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

class RNVideoPlayerView: RNVideoPlayerLayers, UIGestureRecognizerDelegate {
  private var fullScreenButtonLayer = UIButton()
  private var fullScreenLayers = CAShapeLayer()
  var circleImage: UIImage!
  var playPauseSvg = CAShapeLayer()
  var playButton = UIButton()
  var forwardButton = UIButton()
  var backwardButton = UIButton()
  var fullScreenButton = UIButton()
  var videoTimeForChange: Double?
  // dimensions
  var playButtonSize = CGFloat(80)
  
  
  private var hasCalledSetup = false
  private var player: AVPlayer?
  private var hasAutoPlay = false
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
        seekSlider.maximumTrackTintColor = hexStringToUIColor(hexColor: sliderProps["maximumTrackColor"] as! String)
        seekSlider.minimumTrackTintColor = hexStringToUIColor(hexColor: sliderProps["minimumTrackColor"] as! String)
        seekSlider.maximumTrackTintColor = hexStringToUIColor(hexColor: sliderProps["maximumTrackColor"] as! String)
        seekSlider.maximumTrackTintColor = hexStringToUIColor(hexColor: sliderProps["maximumTrackColor"] as! String)
        self.circleImage = self.makeCircle(size: CGSize(width: sliderProps["thumbSize"] as? CGFloat ?? 20, height: sliderProps["thumbSize"] as? CGFloat ?? 20), backgroundColor: hexStringToUIColor(hexColor: sliderProps["thumbColor"] as! String))
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
  
  @objc var autoPlay: Bool = false {
    didSet {
      self.hasAutoPlay = autoPlay
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
      addVideoPlayerSubview()
    }
  }
  
  private func addVideoPlayerSubview() {
    guard let avPlayer = player else { return }
    // View
    playerContainerView = UIView()
    playerContainerView.backgroundColor = .black
    playerContainerView.frame = bounds
    
    addSubview(playerContainerView)
    
    // player
    let videoLayer = AVPlayerLayer(player: avPlayer)
    willTransitionOrientation(videoLayer)
    
    playerContainerView.layer.addSublayer(videoLayer)
    
    
    // add button
    playerContainerView.addSubview(playButton)
    playButton.frame = CGRect(x: playerContainerView.bounds.midX - (playButtonSize/2), y: playerContainerView.bounds.midY - (playButtonSize/2), width: playButtonSize, height: playButtonSize)
    playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
    
    if playPauseSvg.path == nil {
      playButton.layer.addSublayer(pauseSvg())
    }
    
    // add forward button
    forwardButton.frame = CGRect(origin: CGPoint(x: playButton.frame.maxX + 30, y: playButton.frame.minY), size: CGSize(width: playButton.frame.width, height: playButton.frame.height))
    let forwardSvgLayer = forwardLayer(timeValueForChange!)
    forwardSvgLayer.position = CGPoint(x: forwardButton.bounds.midX + forwardSvgLayer.bounds.width / 2, y: forwardButton.bounds.midY + forwardSvgLayer.bounds.height / 2)
    forwardButton.layer.addSublayer(forwardSvgLayer)
    forwardButton.addTarget(self, action: #selector(fowardTime), for: .touchUpInside)
    
    playerContainerView.addSubview(forwardButton)
    
    // add backward button
    backwardButton.frame = CGRect(origin: CGPoint(x: (playButton.frame.minX - playButton.frame.width) - 30, y: playButton.frame.minY), size: CGSize(width: playButton.frame.width, height: playButton.frame.height))
    let backwardSvgLayer = backwardLayer(timeValueForChange!)
    backwardSvgLayer.position = CGPoint(x: forwardButton.bounds.midX + backwardSvgLayer.bounds.width / 2, y: forwardButton.bounds.midY + backwardSvgLayer.bounds.height / 2)
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
    
    // add fullScreen icon

    fullScreenButtonLayer.frame = CGRect(x: playerContainerView.bounds.maxX - (playerContainerView.layoutMargins.right + playButtonSize), y: playerContainerView.bounds.maxY - (playerContainerView.layoutMargins.bottom + playButtonSize/2), width: playButtonSize, height: playButtonSize)
    if fullScreenLayers.path == nil {
      fullScreenButtonLayer.layer.addSublayer(fullScreenShapeLayer())
    }
    fullScreenButtonLayer.addTarget(self, action: #selector(onToggleOrientation), for: .touchUpInside)
    playerContainerView.addSubview(fullScreenButtonLayer)
    
    avPlayer.currentItem?.addObserver(self, forKeyPath: "status", options: [], context: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
    //    NotificationCenter.default.addObserver(self, selector: #selector(nil), name: UIDevice.orientationDidChangeNotification, object: nil)
    if hasAutoPlay {
      avPlayer.play()
    }
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
    labelCurrentTime.text = (self.stringFromTimeInterval(interval: currenTimeInSecond) + "  " + self.stringFromTimeInterval(interval: (player?.currentItem?.duration.seconds)!))
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
    
    if player!.rate == 0
    {
      player?.play()
    }
  }
  
  private func configureSeekSliderLayout() {
    seekSlider.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      seekSlider.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 20),
      seekSlider.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -20),
      seekSlider.bottomAnchor.constraint(equalTo: playerContainerView.layoutMarginsGuide.bottomAnchor),
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
  
  
  private func hexStringToUIColor(hexColor: String) -> UIColor {
    let stringScanner = Scanner(string: hexColor)
    
    if(hexColor.hasPrefix("#")) {
      stringScanner.scanLocation = 1
    }
    
    var color: UInt32 = 0
    stringScanner.scanHexInt32(&color)
    
    let r = CGFloat(Int(color >> 16) & 0x000000FF)
    let g = CGFloat(Int(color >> 8) & 0x000000FF)
    let b = CGFloat(Int(color) & 0x000000FF)
    
    return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
    
  }
  
  private func stringFromTimeInterval(interval: TimeInterval) -> String {
    let interval = Int(interval)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    let hours = (interval / 3600)
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }
  
  @objc private func playButtonTapped() {
    if player?.rate == 0 {
      player?.play()
      playPauseSvg = self.pauseSvg()
    } else {
      player?.pause()
      playPauseSvg = self.playSvg()
    }
    
    let transition = CATransition()
    transition.type = .reveal
    transition.duration = 1.0
    
    
    playButton.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    playButton.layer.sublayers?.forEach { $0.add(transition, forKey: nil)}
    playButton.layer.addSublayer(playPauseSvg)
  }
  
  private func playSvg() -> CAShapeLayer {
    let svgPath = UIBezierPath()
    svgPath.move(to: CGPoint(x: 0, y: 0))
    svgPath.addLine(to: CGPoint(x: 20, y: 15))
    svgPath.addLine(to: CGPoint(x: 0, y: 32))
    svgPath.close()
    
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = svgPath.cgPath
    shapeLayer.fillColor = UIColor.white.cgColor
    
    shapeLayer.frame = CGRect(x: playButton.bounds.midX - svgPath.bounds.width / 2, y: playButton.bounds.midY - svgPath.bounds.height / 2, width: svgPath.bounds.width, height: svgPath.bounds.height)
    return shapeLayer
  }
  
  private func pauseSvg() -> CAShapeLayer {
    let svgPath = UIBezierPath()
    
    svgPath.move(to: CGPoint(x: -15, y: 0))
    svgPath.addLine(to: CGPoint(x: -5, y: 0))
    svgPath.addLine(to: CGPoint(x: -5, y: 32))
    svgPath.addLine(to: CGPoint(x: -15, y: 32))
    svgPath.close()
    
    svgPath.move(to: CGPoint(x: 5, y: 0))
    svgPath.addLine(to: CGPoint(x: 15, y: 0))
    svgPath.addLine(to: CGPoint(x: 15, y: 32))
    svgPath.addLine(to: CGPoint(x: 5, y: 32))
    svgPath.close()
    
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = svgPath.cgPath
    shapeLayer.fillColor = UIColor.white.cgColor
    
    shapeLayer.frame = CGRect(x: playButton.bounds.midX, y: playButton.bounds.midY - svgPath.bounds.height / 2, width: svgPath.bounds.width, height: svgPath.bounds.height)
    
    return shapeLayer
  }
  
  @objc private func fowardTime() {
    self.changeVideoTime(time: Double(truncating: timeValueForChange!))
  }
  
  @objc private func backwardTime() {
    self.changeVideoTime(time: -Double(truncating: timeValueForChange!))
  }
  
  private func changeVideoTime(time: Double){
    guard let currentTime = self.player?.currentTime() else { return }
    let seekTimeSec = CMTimeGetSeconds(currentTime).advanced(by: time)
    let seekTime = CMTime(value: CMTimeValue(seekTimeSec), timescale: 1)
    self.player?.seek(to: seekTime, completionHandler: {completed in})
  }
  
  @objc public func onToggleOrientation() {
    if #available(iOS 16.0, *) {
      if window?.windowScene?.interfaceOrientation.isPortrait == true {
        fullScreenLayers = self.exitFullScreenShapeLayer()
        window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
          print(error.localizedDescription)
        }
        
      } else {
        fullScreenLayers = self.fullScreenShapeLayer()
        window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
          print(error.localizedDescription)
        }
        
      }
    } else {
      if UIInterfaceOrientation.portrait == .portrait {
        let orientation = UIInterfaceOrientation.landscapeRight.rawValue
        fullScreenLayers = self.exitFullScreenShapeLayer()
        UIDevice.current.setValue(orientation, forKey: "orientation")
      } else {
        fullScreenLayers = self.fullScreenShapeLayer()
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
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first {
      playerContainerView.subviews.forEach {$0.isHidden = false}
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: { [self] in
      playerContainerView.subviews.forEach {$0.isHidden = true}
    })
  }
  
  private func willTransitionOrientation(_ layer: AVPlayerLayer) {
    DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.05, execute: { [self] in
      layer.frame = playerContainerView.bounds
      if #available(iOS 13.0, *) {
        if window?.windowScene?.interfaceOrientation.isLandscape == true {
          layer.videoGravity = .resizeAspectFill
        }
      } else {
        if UIDevice.current.orientation.isLandscape {
          layer.videoGravity = .resizeAspectFill
        }
      }
    })
  }
}
