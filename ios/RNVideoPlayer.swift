import AVKit
import React
import AVFoundation

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
        guard let avPlayer = player else { return }
        
        let videoLayer = AVPlayerLayer(player: avPlayer)
        videoLayer.frame = bounds
        videoLayer.videoGravity = .resizeAspectFill
        
        layer.addSublayer(videoLayer)
        
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
    
    @objc func setSeek(_ seek: Float) {
        let time = CMTime(seconds: Double(seek), preferredTimescale: 1)
        player?.seek(to: time)
    }
    
    @objc func setSource(_ source: String) {
        setupVideoPlayer(source)
    }
    
    @objc func setPaused(_ paused: Bool) {
        if paused {
            player?.rate = 0.0
            player?.pause()
        } else {
            player?.play()
            player?.rate = currentRate
        }
    }
    
    @objc func setAutoPlay(_ autoPlay: Bool) {
        hasAutoPlay = autoPlay
    }
}
