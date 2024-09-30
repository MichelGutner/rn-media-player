import AVKit
import SwiftUI
import UIKit
import React
import AVFoundation

@available(iOS 14.0, *)
@objc(RNVideoPlayer)
class RNVideoPlayer: RCTViewManager {
  @objc override func view() -> (RNVideoPlayerView) {
    return RNVideoPlayerView()
  }
  
  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}

@available(iOS 14.0, *)
class RNVideoPlayerView : UIView {
    private var uiView = UIView()
    
    private var player: AVPlayer?
    private var isInitialized = false
    private var isFullScreen = false
    private var UIControlsProps: HashableControllers? = .none
    private var autoEnterFullscreenOnLandscape = false
    
    @objc var autoPlay: Bool = false
    @objc var menus: NSDictionary? = [:]
    @objc var onMenuItemSelected: RCTBubblingEventBlock?
    
    @objc var onVideoProgress: RCTBubblingEventBlock?
    @objc var onLoaded: RCTBubblingEventBlock?
    @objc var onCompleted: RCTBubblingEventBlock?
    @objc var onFullScreen: RCTDirectEventBlock?
    @objc var onError: RCTDirectEventBlock?
    @objc var onBuffer: RCTDirectEventBlock?
    @objc var onBufferCompleted: RCTDirectEventBlock?
    @objc var onGoBackTapped: RCTDirectEventBlock?
    @objc var onVideoDownloaded: RCTDirectEventBlock?
    @objc var onDownloadVideo: RCTDirectEventBlock?
    @objc var onPlayPause: RCTDirectEventBlock?
    
    @objc var thumbnailFramesSeconds: Float = 1.0
    @objc var screenBehavior: NSDictionary = [:]
    
    @objc var controlsProps: NSDictionary? = [:]
    @objc var tapToSeek: NSDictionary? = [:]
    
    @objc var source: NSDictionary? = [:] {
        didSet {
            initializePlayer(source)
        }
    }
    
    @objc var rate: Float = 0.0 {
        didSet {
            NotificationCenter.default.post(name: .AVPlayerRateDidChange, object: nil, userInfo: ["rate": rate])
        }
    }
    
    @objc var paused: Bool = false {
        didSet {
            self.onPaused(paused)
        }
    }
    
    @objc var changeQualityUrl: String = "" {
        didSet {
            let url = changeQualityUrl
            if (url.isEmpty) { return }
            self.onChangePlaybackQuality(URL(string: url)!)
        }
    }
    
    @objc var resizeMode: NSString = "contain"
    
    private func initializePlayer(_ source: NSDictionary?) {
        let url = source?["url"] as? String
        let startTime = source?["startTime"] as? Float
        cleanupPreviousVideo()
        
        player = AVPlayer(url: URL(string: url!)!)
        
        guard let player = player else { return }
        player.currentItem?.seek(to: CMTime(seconds: Double(startTime ?? 0), preferredTimescale: 2), completionHandler: nil)
        
        player.actionAtItemEnd = .none
        player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        player.addObserver(self, forKeyPath: "rate", options: [.new, .old], context: nil)
        
        player.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "playbackBufferFull", options: .new, context: nil)
        self.setNeedsLayout()
    }
    
  private func setup() {
    uiView.removeFromSuperview()
    let thumbnailsProps = source?["thumbnails"] as? NSDictionary
    
    guard let avPlayer = player else { return }
    if let controllersProps = controlsProps {
      let playbackProps = PlaybackControlHashableProps(dictionary: controllersProps["playback"] as? NSDictionary)
      let seekSliderProps = SeekSliderControlHashableProps(dictionary: controllersProps["seekSlider"] as? NSDictionary)
      let timeCodesProps = TimeCodesHashableProps(dictionary: controllersProps["timeCodes"] as? NSDictionary)
      let settingsProps = SettingsControlHashableProps(dictionary: controllersProps["settings"] as? NSDictionary)
      let fullScreenProps = FullScreenControlHashableProps(dictionary: controllersProps["fullScreen"] as? NSDictionary)
      let downloadProps = DownloadControlHashableProps(dictionary: controllersProps["download"] as? NSDictionary)
      let toastProps = ToastHashableProps(dictionary: controllersProps["toast"] as? NSDictionary)
      let headerProps = HeaderControlHashableProps(dictionary: controllersProps["header"] as? NSDictionary)
      let loadingProps = LoadingHashableProps(dictionary: controllersProps["loading"] as? NSDictionary)
      
      UIControlsProps = HashableControllers(
        playbackControl: playbackProps,
        seekSliderControl: seekSliderProps,
        timeCodesControl: timeCodesProps,
        settingsControl: settingsProps,
        fullScreenControl: fullScreenProps,
        downloadControl: downloadProps,
        toastControl: toastProps,
        headerControl: headerProps,
        loadingControl: loadingProps
      )
    }
    
    let mode = Resize(rawValue: resizeMode as String)
    let videoGravity = self.videoGravity(mode!)
    
    if (autoPlay) {
      avPlayer.play()
    }
    
    if let autoEnterFullscreen = screenBehavior["autoEnterFullscreenOnLandscape"] as? Bool {
      self.autoEnterFullscreenOnLandscape = autoEnterFullscreen
    }
    
    let uiHostingView = UIHostingController(rootView: VideoPlayerView(
      safeAreaInsets: safeAreaInsets,
      player: avPlayer,
      options: menus,
      controls: PlayerControls(
        togglePlayback: {
          if (avPlayer.timeControlStatus == .playing) {
            avPlayer.pause()
          } else {
            avPlayer.rate = self.rate
            avPlayer.play()
          }
          self.onPlayPause?(["isPlaying": avPlayer.timeControlStatus == .playing])
        },
        optionSelected: { name, value in
          self.onMenuItemSelected?(["name": name, "value": value])
        },
        toggleFullScreen: { [self] in
          toggleFullScreen(!isFullScreen)
        }
      ),
      thumbNailsProps: thumbnailsProps,
      enterInFullScreenWhenDeviceRotated: autoEnterFullscreenOnLandscape,
      videoGravity: videoGravity,
      UIControlsProps: UIControlsProps,
      tapToSeek: tapToSeek
    ))
    
    uiView = uiHostingView.view
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    uiView.backgroundColor = .black
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    if (!isInitialized) {
      isInitialized = true
      setup()
    }

    let currentOrientation = UIDevice.current.orientation
    
    
    if autoEnterFullscreenOnLandscape, currentOrientation.isLandscape {
      DispatchQueue.main.asyncAfter(deadline: .now()) { [self] in
        toggleFullScreen(true)
      }
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now()) { [self] in
      uiView.backgroundColor = .black
      uiView.clipsToBounds = true
      
      
      if (isFullScreen) {
        uiView.frame = UIScreen.main.bounds
        return
      }
      
      if frame.height > UIScreen.main.bounds.height {
        withAnimation(.easeInOut(duration: 0.35)) {
          uiView.frame = UIScreen.main.bounds
        }
        
      } else {
        withAnimation(.easeInOut(duration: 0.35)) {
          uiView.frame = bounds
        }
      }
      superview?.addSubview(uiView)
    }
    
    super.layoutSubviews()
  }
    
    @objc private func orientationDidChange() {
      let currentOrientation = UIDevice.current.orientation

        
        if autoEnterFullscreenOnLandscape, currentOrientation.isLandscape {
          DispatchQueue.main.asyncAfter(deadline: .now()) { [self] in
            toggleFullScreen(true)
          }
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            NotificationCenter.default.post(name: .AVPlayerRateDidChange, object: player)
        }
        if keyPath == "status" {
            if player?.status == .readyToPlay {
//                setup()
            }
        } else if object is AVPlayerItem {
            switch keyPath {
            case "playbackBufferEmpty":
                // handle buffer empty
                break
            case "playbackLikelyToKeepUp":
                // handle playback likely to keep up
                break
            case "playbackBufferFull":
                // handle buffer full
                break
            default:
                break
            }
        }
    }
    
    @objc func toggleFullScreen(_ fullScreen: Bool) {
//        let transition = CATransition()
//        transition.type = .fade
//        transition.duration = 0.15
//        
//        uiView.layer.add(transition, forKey: kCATransition)
            if fullScreen {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: { [self] in
                    uiView.removeFromSuperview()
                    uiView.frame = UIScreen.main.bounds
                    superview?.addSubview(uiView)
                })
            } else {
                uiView.removeFromSuperview()
                
                if frame.height > UIScreen.main.bounds.height {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        uiView.frame = UIScreen.main.bounds
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        uiView.frame = frame
                    }
                }
                
                superview?.addSubview(uiView)
            }
            
            isFullScreen = fullScreen
    }
    
    @objc private func onPaused(_ paused: Bool) {
        if paused {
            player?.pause()
        } else {
            player?.play()
        }
    }

    deinit {
        player?.removeObserver(self, forKeyPath: "status")
        player?.currentItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        player?.currentItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        player?.currentItem?.removeObserver(self, forKeyPath: "playbackBufferFull")
    }
}


protocol PlayerControlsProtocol {
    func togglePlayback()
}

struct PlayerControls {
    var togglePlayback: () -> Void
    var optionSelected: (_ label: String, _ value: Any) -> Void
    var toggleFullScreen: () -> Void
}



struct Controls {
    var menuItemSelected: (_ label: String, _ value: Any) -> Void
}

@available(iOS 14.0, *)
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
  
    private func onChangePlaybackQuality(_ url: URL) {
        guard let player = player else { return }
        
        if (url == urlOfCurrentPlayerItem(player: player)) {
            return
        }
        let currentTime = player.currentItem?.currentTime() ?? CMTime.zero
        let asset = AVURLAsset(url: url)
        let newPlayerItem = AVPlayerItem(asset: asset)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [self] in
            player.replaceCurrentItem(with: newPlayerItem)
            player.seek(to: currentTime)
            
            newPlayerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
            var playerItemStatusObservation: NSKeyValueObservation?
            playerItemStatusObservation = newPlayerItem.observe(\.status, options: [.new]) { [weak self] (item, _) in
                guard item.status == .readyToPlay else {
                    self?.onError?(extractPlayerErrors(item))
                    return
                }
                playerItemStatusObservation?.invalidate()
            }
        })
    }
  
  private func urlOfCurrentPlayerItem(player : AVPlayer) -> URL? {
    return ((player.currentItem?.asset) as? AVURLAsset)?.url
  }
  
  private func cleanupPreviousVideo() {
      player?.pause()
    
      player?.removeObserver(self, forKeyPath: "status")
      player?.currentItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
      player?.currentItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
      player?.currentItem?.removeObserver(self, forKeyPath: "playbackBufferFull")
    
      player = nil
  }
}
