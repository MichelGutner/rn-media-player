//
//  Forward.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 31/01/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct ForwardView : View {
  var onTap: () -> Void
  
  var body: some View {
  
      Button {
        onTap()
      } label : {
        Image(systemName: "arrow.down.right.and.arrow.up.left")
          .font(.system(size: calculateFrameSize(size22, variantPercent20)))
          .foregroundColor(.white)
      }
    }
}

//fullScreenImage = fullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
