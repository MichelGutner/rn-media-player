//
//  SettingsManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 09/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)

struct SettingsManager : View {
  var onTap: () -> Void
  var size: CGFloat
  var isTapped: Bool
  
  var body: some View {
    HStack {
      Button (action: {
        withAnimation(.linear(duration: 0.2)) {
          onTap()
        }
      }) {
        Image(systemName: "gear")
          .font(.system(size: size))
          .foregroundColor(.white)
          .rotationEffect(.init(degrees: isTapped ? 180 : 0))
      }
    }
    .fixedSize(horizontal: true, vertical: true)
  }
}
