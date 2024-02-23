//
//  CustomVideoPlayer.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 22/02/24.
//

import Foundation
import SwiftUI
import AVKit

@available(iOS 13.0, *)
struct CustomVideoPlayer : UIViewControllerRepresentable {
  var player: AVPlayer
  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let controller  = AVPlayerViewController()
    controller.player = player
    controller.showsPlaybackControls = false
    controller.player?.automaticallyWaitsToMinimizeStalling = true
    
    return controller
  }
  
  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    
  }
}
