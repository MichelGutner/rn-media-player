//
//  AVPlayerLayer.swift
//  Pods
//
//  Created by Michel Gutner on 10/01/25.
//


import Foundation
import AVFoundation
import AVKit


/// Manager the video layer  (`AVPlayerLayer`) .
open class MediaPlayerLayerManager: AVPlayerLayer {
  public override init() {
    super.init()
  }
  
  public override init(layer: Any) {
    super.init(layer: layer)
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  /// Connect player directly to `MediaPlayerLayerManager`.
  /// - Parameter player: The connected player instance.
  open func attachPlayer(with player: AVPlayer) {
    self.player = player
    self.name = UUID().uuidString
    appConfig.log("[MediaPlayerLayerManager] Connected player layer with ID: \(self.name ?? "unknown")")
  }
  
  /// Remove player instance and disconnect current layer.
  open func detachPlayer() {
    guard self.player != nil else {
      appConfig.log("[MediaPlayerLayerManager] No player to detach.")
      return
    }
    
    appConfig.log("[MediaPlayerLayerManager] Disconnected player with ID: \(self.name ?? "unknown")")
    self.removeFromSuperlayer()
  }
  
  /// Define o quadro (frame) do layer.
  /// - Parameter frame: O quadro a ser aplicado.
  open func setLayerFrame(to frame: CGRect) {
    self.frame = frame
  }
}
