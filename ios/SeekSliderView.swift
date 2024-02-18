//
//  SeekSliderView.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 14/02/24.
//

import Foundation
import SwiftUI
import AVKit
import AVFoundation

@available(iOS 13.0, *)
struct SeekSliderView : View {
  weak var avPlayer: AVPlayer?
  var geometry: GeometryProxy
  
  @GestureState private var isDragging: Bool = false
  @State private var progress: CGFloat = 0
  @State private var lastDraggedProgress: CGFloat = 0
  @State private var timeObserver: Any?
  
  var body: some View {
    ZStack(alignment: .leading) {
      Rectangle()
        .fill(.gray)
      
      Rectangle()
        .fill(.red)
        .frame(width: max(geometry.size.width * progress, 0))
      HStack {}
        .overlay(
          Circle()
            .fill(.red)
            .frame(width: 15, height: 15)
            .frame(width: 50, height: 50)
            .contentShape(Rectangle())
            .offset(x: geometry.size.width * progress)
            .gesture(
              DragGesture()
                .updating($isDragging, body: { _, out, _ in
                  out = true
                })
                .onChanged({ value in
                  let translationX: CGFloat = value.translation.width
                  let calculatedProgress = (translationX / geometry.size.width) + lastDraggedProgress
                  progress = max(min(calculatedProgress, 1), 0)
                })
                .onEnded({ value in
                  lastDraggedProgress = progress
                  
                  if let currentPlayerItem = avPlayer?.currentItem {
                    let duration = currentPlayerItem.duration.seconds

                    avPlayer?.seek(to: .init(seconds: duration * progress, preferredTimescale: 1))
                  }
                })
            )
        )
    }
    .frame(height: 3)
    .onAppear {
      periodicTimeObserver()
    }
  }
  
  
  func periodicTimeObserver() {
      let interval = CMTime(value: 1, timescale: 1)
      timeObserver = avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [self] time in
//          progress = stringFromTimeInterval(interval: time.seconds)
        if let currentPlayerItem = avPlayer?.currentItem {
          let duration = currentPlayerItem.duration.seconds
          progress = (time.seconds / duration)
          lastDraggedProgress = progress
        }
          

          // Update the progress position during playback
//          updateProgressPosition()
      }
  }
}
