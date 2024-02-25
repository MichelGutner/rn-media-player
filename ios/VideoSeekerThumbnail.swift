//
//  VideoSeekerThumbnail.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 25/02/24.
//

import Foundation
import SwiftUI
import AVKit

@available(iOS 13.0, *)
struct VideoSeekerThumbnail : View {
  var player: AVPlayer
  var videoSize: CGSize
  var draggingImage: UIImage? {
    didSet {
      print("testing")
    }
  }
  var isDragging: Bool
  var thumbOffsetX: Double
  
  init(player: AVPlayer, videoSize: CGSize, draggingImage: UIImage? = nil, isDragging: Bool, thumbOffsetX: Double) {
    self.player = player
    self.videoSize = videoSize
    self.draggingImage = draggingImage
    self.isDragging = isDragging
    self.thumbOffsetX = thumbOffsetX
  }
  
  var body: some View {
    let thumbSize: CGSize = .init(width: 200, height: 100)
    
    HStack {
      if let draggingImage {
        VStack {
          Image(uiImage: draggingImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: thumbSize.width, height: thumbSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(.white, lineWidth: 2)
            )
          Group {
            if let currentItem =  player.currentItem {
              Text(stringFromTimeInterval(interval: TimeInterval(truncating: (thumbOffsetX * currentItem.duration.seconds) as NSNumber)))
                .font(.caption)
                .foregroundColor(.white)
                .fontWeight(.semibold)
            }
          }
        }
      } else {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
          .fill(.black)
          .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
              .stroke(.white, lineWidth: 2)
          )
      }
    }
    .frame(width: thumbSize.width, height: thumbSize.height)
    .opacity(isDragging ? 1 : 0)
    .offset(x: thumbOffsetX * (videoSize.width - thumbSize.width))
    .animation(.easeInOut(duration: 0.2), value: isDragging)
    
  }
}
