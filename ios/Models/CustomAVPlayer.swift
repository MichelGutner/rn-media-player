//
//  CustomAVPlayer.swift
//  Pods
//
//  Created by Michel Gutner on 09/11/24.
//

import SwiftUI
import AVKit

struct CustomAVPlayer: UIViewControllerRepresentable {
  var player: AVPlayer?
  
  func makeUIViewController(context: Context) -> some AVPlayerViewController {
    
    let controller = AVPlayerViewController()
    controller.player = player
    controller.showsPlaybackControls = false

    controller.player?.play()
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    //
  }
  
}
