//
//  FullScreenManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 07/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct FullScreenManager : View {
  var isFullScreen: Bool = false
  var onTap: () -> Void
  var config: NSDictionary?
  
  @State private var dynamicFontSize: CGFloat = calculateFrameSize(size20, variantPercent30)
  
  var body: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
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
    }
  }
  
  private func updateDynamicFontSize() {
    dynamicFontSize = calculateFrameSize(size20, variantPercent30)
  }
}
