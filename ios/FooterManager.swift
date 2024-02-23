//
//  FullScreenManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 07/02/24.
//

import Foundation
import SwiftUI
import AVKit

@available(iOS 13.0, *)
struct FooterManager : View {
  @ObservedObject private var playbackObserver = PlayerObserver()
  @State private var dynamicFontSize: CGFloat = calculateFrameSize(size18, variantPercent30)
  @State private var dynamicDurationTextSize: CGFloat = calculateFrameSize(size10, variantPercent20)
  @State private var playbackDuration: Double = 1.0
  @State private var sliderValue = 0.0
  
  @GestureState private var isDragging: Bool = false
  @State private var progress: CGFloat = 0.5
  @State private var lastDraggedProgress: CGFloat = 0
  
  var avPlayer: AVPlayer
  var isFullScreen: Bool = false
  var onTap: () -> Void
  weak var config: NSDictionary?
  
  
  var body: some View {
    VStack {
      Spacer()
      HStack {
        VideoSeekerView()
        //        Slider(value: $sliderValue, in: 0...1)
        //          .gesture(
        //            DragGesture(minimumDistance: 0)
        //              .onChanged { change in
        //                let xOffset = change.location.x
        //                                    let percentSlider = xOffset / playbackDuration
        //                                    print("percent", percentSlider)
        //                print(xOffset)
        //              }
        //              .onEnded { change in
        //                let endOffsetX = change.location.x
        //                //                    let percentSlider = endOffsetX / geometry.size.width
        //                //                    print("percent", percentSlider)
        //              }
        //          )
        Text(stringFromTimeInterval(interval: playbackDuration))
          .foregroundColor(.white)
          .font(.system(size: dynamicDurationTextSize))
        Button (action: {
          onTap()
        }) {
          let color = config?["color"] as? String
          let isHidden = config?["hidden"] as? Bool
          Image(
            systemName:
              isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
          )
          .font(.system(size: dynamicFontSize))
          .foregroundColor(Color(transformStringIntoUIColor(color: color)))
          .rotationEffect(.init(degrees: 90))
          .opacity(isHidden ?? false ? 0 : 1)
        }
      }
      .padding(.bottom, 12)
      .padding(.trailing, 24)
    }
    .onAppear {
      NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: .main) { _ in
        updateDynamicFontSize()
      }
      NotificationCenter.default.addObserver(
        playbackObserver,
        selector: #selector(PlayerObserver.playbackItem(_:)),
        name: .AVPlayerItemNewAccessLogEntry,
        object: avPlayer.currentItem
      )
    }
    .onReceive(playbackObserver.$playbackDuration) { duration in
      if duration != 0.0 {
        playbackDuration = duration
        //        sliderValue = 15.05
      }
      if  avPlayer.currentItem?.duration.seconds != 0.0 {
        sliderValue = avPlayer.currentTime().seconds / (avPlayer.currentItem?.duration.seconds)!
        playbackDuration = (avPlayer.currentItem?.duration.seconds)!
      }
    }
  }
  
  private func updateDynamicFontSize() {
    sliderValue = 150.0
    dynamicFontSize = calculateFrameSize(size18, variantPercent30)
    dynamicDurationTextSize = calculateFrameSize(size10, variantPercent20)
  }
  
  @ViewBuilder
  func VideoSeekerView() -> some View {
      ZStack(alignment: .leading) {
        Rectangle()
          .fill(.gray)
          .frame(width: UIScreen.main.bounds.width * 0.7)
        
        Rectangle()
          .fill(.red)
          .frame(width: max((UIScreen.main.bounds.width * 0.6) * progress, 0))
        HStack {}
          .overlay(
            Circle()
              .fill(.red)
              .frame(width: 15, height: 15)
              .frame(width: 50, height: 50)
              .contentShape(Rectangle())
              .offset(x: (UIScreen.main.bounds.width * 0.6) * progress)
              .gesture(
                DragGesture()
                  .updating($isDragging, body: { _, out, _ in
                    out = true
                  })
                  .onChanged({ value in
                    let translationX: CGFloat = value.translation.width
                    let calculatedProgress = (translationX / (UIScreen.main.bounds.width * 0.6)) + lastDraggedProgress
                    progress = max(min(calculatedProgress, 1), 0)
                  })
                  .onEnded({ value in
                    lastDraggedProgress = progress
                  })
              )
          )
      }
      .frame(height: 3)
    }
      
//  }
}
