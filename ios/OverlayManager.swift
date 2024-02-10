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
  var onTapBackward: () -> Void
  var onTapForward: () -> Void
  var advanceValue: Int
  
  var onTapFullScreen: () -> Void
  var isFullScreen: Bool
  var fullScreenConfig: NSDictionary?
  var suffixAdvanceValue: String

  var onTapExit: () -> Void
  var onTapSettings: () -> Void
  
  var body: some View {
    ZStack {
      Color(.clear).opacity(variantPercent40)
      VStack {
        HStack(spacing: size60) {
          DoubleTapSeek(onTap:  {
            onTapBackward()
          },
          advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue)
          
          DoubleTapSeek(isForward: true, onTap:  {
            onTapForward()
          }, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue)
        }
      }
      
      
    }
    .edgesIgnoringSafeArea(Edge.Set.all)
    .overlay(
      GeometryReader { _ in
        FullScreenMAnager(isFullScreen: isFullScreen, onTap: onTapFullScreen, config: fullScreenConfig)
        HeaderManager(onTap: onTapExit, onTapSettings: onTapSettings)
      }
    )
  }
}
