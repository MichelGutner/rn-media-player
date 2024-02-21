//
//  ControlsManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 11/02/24.
//

import Foundation
import SwiftUI
import AVKit

@available(iOS 13.0, *)
struct ControlsManager: View {
  var safeAreaInsets: UIEdgeInsets
  var avPlayer: AVPlayer
  var videoTitle: String
  var onTapGestureBackdrop: (Bool) -> Void
  var onVideoProgress: ([String: Any]) -> Void
  var onSettingItemTapped: (String) -> Void
  
  @State private var isTapped: Bool = false
  
  // MARK: -- FullScreen
  var isFullScreen: Bool = false
  var onTapFullScreen: () -> Void
  var configFullScreen: NSDictionary?
  
  // MARK: -- Double Tap
  var onTapForward: (Int) -> Void
  var onTapBackward: (Int) -> Void
  var advanceValue: Int = 10
  var suffixAdvanceValue: String
  var isFinished: () -> Void
  
  // MARK: -- Settings
  var onTapSettings: () -> Void
  
  // MARK: -- exit
  var onTapExit: () -> Void
  
  // MARK: -- PlayPause
  var onTapPlayPause: ([String: Any]) -> Void
  
  var onAppearOverlay: () -> Void
  var onDisappearOverlay: () -> Void
  
  
  var body: some View {
    ZStack {
      DoubleTapManager(
        onTapBackward: { value in
          isTapped = true
          onTapBackward(value)
        },
        onTapForward: { value in
          isTapped = true
          onTapForward(value)
        },
        isFinished: {
          isFinished()
        },
        advanceValue: advanceValue,
        suffixAdvanceValue: suffixAdvanceValue
      )
      .background(Color(.black).opacity(isTapped ? 0 : 0.3))
      .edgesIgnoringSafeArea(.all)
      .onTapGesture {
        isTapped.toggle()
        onTapGestureBackdrop(isTapped)
      }
      .foregroundColor(.white)
      .overlay(
        Group {
          OverlayManager(
            safeAreaInsets: self.safeAreaInsets,
            videoTitle: videoTitle,
            onTapFullScreen: onTapFullScreen,
            isFullScreen: isFullScreen,
            onTapExit: onTapExit,
            onTapSettings: onTapSettings,
            avPlayer: avPlayer,
            onTapPlayPause: { status in
              onTapPlayPause(status)
              onToggleDisplayOverlay()
            },
            onAppearOverlay: {
              onToggleDisplayOverlay()
              onAppearOverlay()
            },
            onDisappearOverlay: {
              onDisappearOverlay()
            },
            onVideoProgress: onVideoProgress,
            onSettingItemTapped: onSettingItemTapped
          )
          .padding(8)
        }
      )
    }
  }
  private func onToggleDisplayOverlay() {
    DispatchQueue.main.asyncAfter(wallDeadline: .now() + 3, execute: {
      if (avPlayer.timeControlStatus != .paused) {
        withAnimation(.easeInOut) {
          isTapped = true
          onTapGestureBackdrop(true)
        }
      }
    })
  }
}

