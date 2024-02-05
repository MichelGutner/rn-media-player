//
//  OverlayLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 04/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct OverlayLayoutManager : View {
  var onTapBackward: () -> Void
  var onTapForward: () -> Void
  
  var body: some View {
    ZStack {
      Color(.clear).opacity(0.4)
      VStack {
        HStack(spacing: 60) {
          DoubleTapSeek {
            onTapBackward()
          }
          
          DoubleTapSeek(isForward: true) {
            onTapForward()
          }
        }
      }
      
    }
    .edgesIgnoringSafeArea(Edge.Set.all)
  }
}
