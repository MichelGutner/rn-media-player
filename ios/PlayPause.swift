//
//  PlayPause.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 04/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)

struct PlayPauseManager: View {
  
  var body: some View {
    Button (action: {
      print("PLAY")
    }) {
      Image(systemName: "play.fill")
        .font(.system(size: calculateFrameSize(size22, variantPercent20)))
        .foregroundColor(.white)
    }
    .fixedSize(horizontal: true, vertical: true)
    .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
  }
  
}
