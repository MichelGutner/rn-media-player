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
  @State private var dynamicFontSize: CGFloat = dynamicSize18v30
  @State private var dynamicDurationTextSize: CGFloat = calculateFrameSize(size10, variantPercent20)
  @State private var playbackDuration: Double = 0.0
  
  var avPlayer: AVPlayer
  var isFullScreen: Bool = false
  var onTap: () -> Void
  var config: NSDictionary?
  
  
  var body: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
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
        selector: #selector(PlayerObserver.playbackItemDuration(_:)),
        name: .AVPlayerItemNewAccessLogEntry,
        object: avPlayer.currentItem
      )
    }
    .onReceive(playbackObserver.$playbackDuration) { duration in
      if duration != 0.0 {
        playbackDuration = duration
      }
      if  avPlayer.currentItem?.duration.seconds != 0.0 {
        playbackDuration = (avPlayer.currentItem?.duration.seconds)!
      }
    }
  }
  
  private func updateDynamicFontSize() {
    dynamicFontSize = dynamicSize18v30
    dynamicDurationTextSize = calculateFrameSize(size10, variantPercent20)
  }
}
