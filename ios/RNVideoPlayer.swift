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
  
  private var hasCalledSetup = false
  private var player: AVPlayer?
  private var hasAutoPlay = false
  private var timeObserver: Any?
  private var currentTime: TimeInterval = 0.0
  private var seekSlider: UISlider! = UISlider(frame:CGRect(x: 0, y:UIScreen.main.bounds.height - 60, width:UIScreen.main.bounds.width, height:10))
  private var playerContainerView: UIView!
  private var labelCurrentTime: UILabel! = UILabel(frame: UIScreen.main.bounds)
  private var labelDuration: UILabel! = UILabel(frame: UIScreen.main.bounds)
  
  
  //maximumTrackColor: '#f6f3f3',
  //  minimumTrackColor: '#7b7777',
  //  thumbSize: 20,
  //  thumbColor: '#e10606',
  
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
        print("ERROR", "AQIO")
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
    if fullScreen  {
      videoLayer.videoGravity = .resizeAspectFill
    }
    playerContainerView.layer.addSublayer(videoLayer)
    
    
    // seek slider monitoring label
    //    let transition = CATransition()
    //    transition.type = CATransitionType.moveIn
    //    transition.duration = 1.0 // Set the duration of the animation (in seconds)
    //    labelCurrentTime.layer.add(transition, forKey: nil)
    labelDuration.textColor = .white
    labelCurrentTime.textColor = .white
    playerContainerView.addSubview(labelCurrentTime)
    playerContainerView.addSubview(labelDuration)
    
    
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
      self.currentTime = time.seconds
      self.onVideoProgress?(["progress": currentTime])
      self.updatePlayerTime()
      self.labelCurrentTime.frame = CGRect(x: seekSlider.frame.origin.x, y: seekSlider.frame.origin.y - 40, width: 80, height: 40)
      self.labelDuration.frame = CGRect(x: seekSlider.frame.maxX - 70, y: seekSlider.frame.origin.y - 40, width: 80, height: 40)
    }
  }
  
  private func updatePlayerTime() {
    guard let currentTitme = self.player?.currentTime() else {return}
    guard let duration = self.player?.currentItem?.duration else {return}
    let currenTimeInSecond = CMTimeGetSeconds(currentTitme)
    let durationTimeInSecond = CMTimeGetSeconds(duration)
    labelCurrentTime.text = self.stringFromTimeInterval(interval: currenTimeInSecond)
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
        self.labelDuration.text = self.stringFromTimeInterval(interval: (player?.currentItem?.duration.seconds)!)
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
}
