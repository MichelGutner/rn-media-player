//
//  CustomVideoPlayer.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 22/02/24.
//

import Foundation
import SwiftUI
import AVKit

@available(iOS 14.0, *)
struct CustomVideoPlayer : UIViewControllerRepresentable {
  var player: AVPlayer
  var videoGravity: AVLayerVideoGravity
  
  
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller  = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.player?.automaticallyWaitsToMinimizeStalling = true
        if #available(iOS 16.0, *) {
            controller.allowsVideoFrameAnalysis = false
        } else {
            // Fallback on earlier versions
        }
        
        return controller
    }
  
  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    uiViewController.videoGravity = videoGravity
  }
}
