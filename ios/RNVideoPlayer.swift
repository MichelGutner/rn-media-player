import AVKit
import React
import AVFoundation
import UIKit

@objc(RNVideoPlayer)
class RNVideoPlayer: RCTViewManager {
  @objc override func view() -> UIView {
    return RNVideoPlayerView()
  }
  
  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }
  
}

class RNVideoPlayerView: UIView {
  let screenWidth = UIScreen.main.bounds.width
  let screenHeight = UIScreen.main.bounds.height
  
  @objc var onVideoProgress: RCTBubblingEventBlock?
  @objc var onLoaded: RCTBubblingEventBlock?
  @objc var onCompleted: RCTBubblingEventBlock?
  @objc var onVideoDuration: RCTBubblingEventBlock?
  private var hasCalledSetup = false
  private var player: AVPlayer?
  var playButton:UIButton?
  private var hasAutoPlay = false
  private var currentRate: Float = 5.0
  private var timeObserver: Any?
  private var currentTime: TimeInterval = 0.0
  private var seekSlider: UISlider! = UISlider(frame:CGRect(x: 0, y:UIScreen.main.bounds.height, width:UIScreen.main.bounds.width, height:10))
  
  
  
  private func setupVideoPlayer(_ source: String) {
    if let url = URL(string: source) {
      player = AVPlayer(url: url)
      player?.actionAtItemEnd = .none
      hasCalledSetup = true
    }
    periodTimeObserver()
  }
  
  override func layoutSubviews() {
    if hasCalledSetup {
      addVideoPlayerSubview()
    }
  }
  
  private func addVideoPlayerSubview() {
    let playButtonWidth:CGFloat = 100
    let playButtonHeight:CGFloat = 45
    guard let avPlayer = player else { return }
    
    // player
    let videoLayer = AVPlayerLayer(player: avPlayer)
    videoLayer.frame = bounds
    videoLayer.videoGravity = .resizeAspectFill
    
    layer.addSublayer(videoLayer)
    
    // playButton native
    playButton = UIButton(type: UIButton.ButtonType.system) as UIButton
    let xPostion:CGFloat = (screenWidth - playButtonWidth) / 2
    let yPostion:CGFloat = (screenHeight - playButtonHeight) / 2
    
    playButton!.frame = CGRect(x:xPostion, y:yPostion, width:playButtonWidth, height:playButtonHeight)
    playButton!.backgroundColor = UIColor.clear
    playButton!.setTitle("Play", for: UIControl.State.normal)
    
    playButton!.tintColor = UIColor.black
    playButton!.addTarget(self, action: #selector(self.playButtonTapped(_:)), for: .touchUpInside)
    
    addSubview(playButton!)
    
    
    seekSlider.addTarget(self, action: #selector(self.seekIsliderValueChanged(_:)), for: .valueChanged)
    seekSlider.tintColor = UIColor.blue
    seekSlider.thumbTintColor = UIColor.blue

    addSubview(seekSlider!)
    configureSeekSliderLayout()

    
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
    }
  }
  
  private func updatePlayerTime() {
    guard let currentTitme = self.player?.currentTime() else {return}
    guard let duration = self.player?.currentItem?.duration else {return}
    let currenTimeInSecond = CMTimeGetSeconds(currentTitme)
    let durationTimeInSecond = CMTimeGetSeconds(duration)
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
        self.onLoaded?(["loaded": true])
      }
      
    }
  }
  
  @objc private func itemDidFinishPlaying(_ notification: Notification) {
    self.onCompleted?(["completed": true])
    removePeriodicTimeObserver()
  }
  
  @objc func setRate(_ rate: Float) {
    player?.rate = rate
    currentRate = rate
  }
  
  @objc func setSource(_ source: String) {
    setupVideoPlayer(source)
  }
  
  @objc func setPaused(_ paused: Bool) {
    if paused {
      player?.pause()
    } else {
      player?.play()
    }
  }
  
  @objc func setAutoPlay(_ autoPlay: Bool) {
    hasAutoPlay = autoPlay
  }
  
  @objc func playButtonTapped(_ sender:UIButton)
  {
    if player?.rate == 0
    {
      player!.play()
      playButton!.setTitle("Pause", for: UIControl.State.normal)
    } else {
      player!.pause()
      playButton!.setTitle("Play", for: UIControl.State.normal)
    }
  }
  
  private var isThumbSeek: Bool = false
  @objc func seekIsliderValueChanged(_ seekSlider: UISlider) {
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
      seekSlider.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      seekSlider.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
    ])
    
    if #available(iOS 11, *) {
      let guide = safeAreaLayoutGuide
      NSLayoutConstraint.activate([
        safeAreaLayoutGuide.topAnchor.constraint(equalToSystemSpacingBelow: safeAreaLayoutGuide.topAnchor, multiplier: 1.0),
        seekSlider.bottomAnchor.constraint(equalToSystemSpacingBelow: safeAreaLayoutGuide.bottomAnchor, multiplier: 1.0)
       ])
    } else {
       let standardSpacing: CGFloat = 8.0
       NSLayoutConstraint.activate([
        safeAreaLayoutGuide.topAnchor.constraint(equalTo: seekSlider.topAnchor, constant: standardSpacing),
        seekSlider.bottomAnchor.constraint(equalTo: seekSlider.bottomAnchor, constant: standardSpacing)
       ])
    }
  }
  
}
