//
//  MediaPlayerAdapter.swift
//  rn-media-player
//
//  Created by Michel Gutner on 01/01/25.
//

import AVKit
import UIKit
import AVFoundation

protocol MediaPlayerAdapter: AnyObject {
  func initializeMediaPlayer(asset: AVAsset)
    func attachAVLayerToView(_ view: UIView)
    func updateAVLayerFrame(_ frame: CGRect)
    func release()
    func onPlay()
    func onPause()
    func addPeriodicTimeObserver(_ block: @escaping (_ time: Double) -> Void)
    func removePeriodicTimeObserver()
}

class MediaPlayerAdapterImpl: MediaPlayerAdapter {
  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  private var observer: Any?
  private var tolerance = CMTime(seconds: 0.1, preferredTimescale: Int32(NSEC_PER_SEC))
  
  var isPlaying: Bool {
    guard let player else {
      return false
    }
    return player.timeControlStatus == .playing
  }
  
  var currentTime: Double {
    player?.currentTime().seconds ?? 0
  }
  var duration: Double {
    player?.currentItem?.duration.seconds ?? 0
  }
  
  func initializeMediaPlayer(asset: AVAsset) {
    let playerItem = AVPlayerItem(asset: asset)
    self.player = AVPlayer(playerItem: playerItem)
    self.playerLayer = AVPlayerLayer(player: player)
    self.playerLayer?.videoGravity = .resizeAspect
  }

  
  func attachAVLayerToView(_ view: UIView) {
    guard let playerLayer = self.playerLayer else {
      return
    }
    playerLayer.frame = view.bounds
    view.layer.addSublayer(playerLayer)
  }
  
  func updateAVLayerFrame(_ frame: CGRect) {
    playerLayer?.frame = frame
  }
  
  func release() {
    playerLayer?.removeFromSuperlayer()
    removePeriodicTimeObserver()
  }
  
  func onPlay() {
    player?.play()
  }
  
  func onPause() {
    player?.pause()
  }
  
  func addPeriodicTimeObserver(_ block: @escaping (_ time: Double) -> Void) {
    guard let player else {
      return
    }
    self.observer = player.addPeriodicTimeObserver(
          forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1),
          queue: .main
      ) { time in
          let seconds = time.seconds
          if seconds.isNaN || seconds.isInfinite {
              return
          }
          block(seconds)
      }
  }
  
  internal func removePeriodicTimeObserver() {
    if let observer {
      player?.removeTimeObserver(observer)
    }
  }
}
