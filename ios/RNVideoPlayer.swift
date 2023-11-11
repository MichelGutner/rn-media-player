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
  @objc var onVideoProgress: RCTBubblingEventBlock?
  @objc var onLoaded: RCTBubblingEventBlock?
  @objc var onCompleted: RCTBubblingEventBlock?
  @objc var onVideoDuration: RCTBubblingEventBlock?
  private var hasCalledSetup = false
  private var player: AVPlayer?
  var playButton:UIButton?
  private var hasAutoPlay = false
  private var currentRate: Float = 1.0
  private var timeObserver: Any?
  private var currentTime: TimeInterval = 0.0
  
  private func setupVideoPlayer(_ source: String) {
      if let url = URL(string: source) {
            player = AVPlayer(url: url)
            player?.actionAtItemEnd = .none
            hasCalledSetup = true
        }
    }
    
  override func layoutSubviews() {
      if hasCalledSetup {
        addVideoPlayerSubview()
        addPeriodicTimeObserver()
      }
    }
    
    private func addVideoPlayerSubview() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
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
      playButton!.setTitle("Pause", for: UIControl.State.normal)
      playButton!.tintColor = UIColor.black
      playButton!.addTarget(self, action: #selector(self.playButtonTapped(_:)), for: .touchUpInside)
      
      addSubview(playButton!)
      
      // seek
        
        avPlayer.currentItem?.addObserver(self, forKeyPath: "status", options: [], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
        if hasAutoPlay {
            avPlayer.play()
        }
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(value: 1, timescale: 2)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
          guard let self = self else { return }
          self.currentTime = time.seconds
          self.onVideoProgress?(["progress": currentTime])
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
            self.onVideoDuration?(["videoDuration": player?.currentItem?.duration.seconds])
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
}
