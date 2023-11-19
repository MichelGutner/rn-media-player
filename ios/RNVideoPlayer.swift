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

class RNVideoPlayerContainerView: UIView {
  
}

class RNVideoPlayerView : UIView {
  let screenWidth = UIScreen.main.bounds.width
  let screenHeight = UIScreen.main.bounds.height
  var circleImage: UIImage!
  var playButton = UIButton()
  var playPauseSvg = CAShapeLayer()
  var forwardButton = UIButton()
  
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
      self.onToggleOrientation(fullScreen)
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
    videoLayer.frame = bounds
    if fullScreen {
      if #available(iOS 13.0, *) {
        if let windowScene = window?.windowScene, windowScene.isFullScreen {
          videoLayer.videoGravity = .resizeAspectFill
        }
      } else {
        if UIDevice.current.orientation.isLandscape {
          videoLayer.videoGravity = .resizeAspectFill
        }
      }
    }
    playerContainerView.layer.addSublayer(videoLayer)
    
    
    // add button
    playButton.frame = CGRect(x: playerContainerView.bounds.midX - 30, y: playerContainerView.bounds.midY - 30, width: 60, height: 60)
    playerContainerView.addSubview(playButton)
    playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
    
    if playPauseSvg.path == nil {
      playButton.layer.addSublayer(pauseSvg())
    }
    
    // add forward button
    forwardButton.frame = CGRect(origin: CGPoint(x: playButton.frame.maxX * 1.25, y: playButton.frame.minY), size: CGSize(width: playButton.frame.width, height: playButton.frame.height))
    forwardButton.layer.addSublayer(forward())
    playerContainerView.addSubview(forwardButton)
    
    // seek slider monitoring label
    labelCurrentTime.textColor = .white
    labelCurrentTime.font = UIFont.systemFont(ofSize: 8)
    playerContainerView.addSubview(labelCurrentTime)
    
    
    // seek slider
    self.configureSliderProps()
    playerContainerView.addSubview(seekSlider!)
    self.configureSeekSliderLayout()
    
    
    avPlayer.currentItem?.addObserver(self, forKeyPath: "status", options: [], context: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
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
      self.labelCurrentTime.frame = CGRect(x: seekSlider.frame.origin.x, y: seekSlider.frame.origin.y - 40, width: 80, height: 40)
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
      seekSlider.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
    ])
  }
  
  @objc private func onToggleOrientation(_ onFullScreen: Bool) {
    if #available(iOS 16.0, *) {
      if onFullScreen {
        window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
          print(error.localizedDescription)
        }
      } else {
        window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
          print(error.localizedDescription)
        }
      }
    } else {
      if onFullScreen {
        let orientation = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(orientation, forKey: "orientation")
      } else {
        let orientation = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(orientation, forKey: "orientation")
      }
    }
  }
  
  @objc private func onChangeRate(_ rate: Float) {
    print(rate)
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
    playButton.layer.addSublayer(playPauseSvg)
    playButton.layer.sublayers?.forEach { $0.add(transition, forKey: nil)}
  }
  private func stringFromTimeInterval(interval: TimeInterval) -> String {
    let interval = Int(interval)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    let hours = (interval / 3600)
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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
    
    shapeLayer.frame = CGRect(x: svgPath.bounds.width, y: svgPath.bounds.height / 2, width: svgPath.bounds.width, height: svgPath.bounds.height)
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
    
    shapeLayer.frame = CGRect(x: svgPath.bounds.width, y: svgPath.bounds.height / 2, width: svgPath.bounds.width, height: svgPath.bounds.height)
    
    return shapeLayer
  }
  
  private func forward() -> CAShapeLayer {
    print("bounds", forwardButton.bounds.midX, "frame", forwardButton.frame.midX)
    let svgPath = UIBezierPath()
    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius: 14, startAngle: 0, endAngle: 4.98, clockwise: true)
    svgPath.append(circlePath)
    
    let trianglePath = UIBezierPath()
    trianglePath.move(to: CGPoint(x: 9, y: 0))
    trianglePath.addLine(to: CGPoint(x: 1.5, y: 5))
    trianglePath.addLine(to: CGPoint(x: 1.5, y: -5))
    
    trianglePath.close()
    
    let triangleLayer = CAShapeLayer()
    triangleLayer.path = trianglePath.cgPath
    triangleLayer.fillColor = UIColor.white.cgColor
    triangleLayer.position = CGPoint(x: svgPath.bounds.midX, y: svgPath.bounds.minY)
    
    
    let numberLayer = CATextLayer()
    numberLayer.string = "15"
    numberLayer.foregroundColor = UIColor.white.cgColor
    numberLayer.alignmentMode = .center
    numberLayer.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
    numberLayer.position = CGPoint(x: svgPath.bounds.midX, y: svgPath.bounds.midY)
    numberLayer.fontSize = 16
    
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = svgPath.cgPath
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.strokeColor = UIColor.white.cgColor
    shapeLayer.lineWidth = 4
    
    shapeLayer.addSublayer(numberLayer)
    shapeLayer.addSublayer(triangleLayer)
    
    shapeLayer.frame.size = CGSize(width: svgPath.bounds.width, height: svgPath.bounds.height)
    shapeLayer.position = CGPoint(x: forwardButton.bounds.midX + svgPath.bounds.width / 2, y: forwardButton.bounds.midY + svgPath.bounds.height / 2)
    return shapeLayer
  }
}
