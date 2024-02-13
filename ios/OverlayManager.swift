//
//  OverlayLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 04/02/24.
//

import Foundation
import SwiftUI
import AVKit

@available(iOS 13.0, *)
struct OverlayManager : View {
  var videoTitle: String
  var onTapFullScreen: () -> Void
  var isFullScreen: Bool
  var fullScreenConfig: NSDictionary?

  var onTapExit: () -> Void
  var onTapSettings: () -> Void
  var avPlayer : AVPlayer
  var onTapPlayPause: ([String: Any]) -> Void

  var onAppearOverlay: () -> Void
  var onDisappearOverlay: () -> Void
  
  var body: some View {
    ZStack {
      FooterManager(avPlayer: avPlayer, isFullScreen: isFullScreen, onTap: onTapFullScreen, config: fullScreenConfig)
      HeaderManager(onTap: onTapExit, onTapSettings: onTapSettings, title: videoTitle)
      PlayPauseManager(player: avPlayer, onTap: { [self] value in
        onTapPlayPause(["status": value])
      })
    }
    .onAppear {
      onAppearOverlay()
    }
    .onDisappear {
      onDisappearOverlay()
    }
  }
}

@available(iOS 13.0, *)
struct DoubleTapManager : View {
  var onTapBackward: (Int) -> Void
  var onTapForward: (Int) -> Void
  var isFinished: () -> Void
  var advanceValue: Int
  var suffixAdvanceValue: String
  
  var body: some View {
    ZStack {
      Color(.clear).opacity(variantPercent10)
      VStack {
        HStack(spacing: size60) {
          DoubleTapSeek(onTap:  onTapBackward, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: isFinished)
          DoubleTapSeek(isForward: true, onTap:  onTapForward, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: isFinished)
        }
      }
    }
    .edgesIgnoringSafeArea(Edge.Set.all)
  }
}
