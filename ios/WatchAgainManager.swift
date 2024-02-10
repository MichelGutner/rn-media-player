//
//  WatchAgainManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 10/02/24.
//

import Foundation
import SwiftUI
import AVKit

@available(iOS 13.0, *)
struct WatchAgainManager : View {
  var onTap: (Float) -> Void
  @State private var isTapped : Bool = false
  @State private var dynamicSize : CGFloat = calculateFrameSize(size20, variantPercent30)
  
  var body: some View {
      VStack(alignment: .center) {
        HStack {
          Button (action: {
            onTap(0.0)
            isTapped.toggle()
          }) {
            Image(systemName: "gobackward")
              .foregroundColor(.white)
              .font(.system(size: dynamicSize))
          }
        }
      }
      .padding(12)
      .fixedSize(horizontal: true, vertical: true)
      .onAppear {
        NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: .main) {_ in
          print("TESTING")
        }
        
      }
  }
  
  private func updateDynamicSize() {
    dynamicSize = calculateFrameSize(size20, variantPercent30)
  }
}
