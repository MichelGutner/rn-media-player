//
//  ExitManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 07/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct HeaderManager : View {
  var onTap: () -> Void
  var onTapSettings: () -> Void
  @State private var isSettingsTapped: Bool = false
  
  @State private var dynamicSize = calculateFrameSize(size20, variantPercent30)
  
  var body: some View {
    VStack {
      HStack {
        Button (action: {
          onTap()
        }) {
          Image(systemName: "arrow.left")
            .font(.system(size: dynamicSize))
            .foregroundColor(.white)
        }
        Spacer()
        SettingsManager(onTap: {
          onTapSettings()
          isSettingsTapped.toggle()
        }, size: dynamicSize, isTapped: !isSettingsTapped)
      }
      
      
    }
    .padding(.leading, 20)
    .padding(.trailing, 20)
    .padding(.top, 16)
    .onAppear {
      NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: .main) { _ in
        updateDynamicSize()
      }
    }
  }
  
  private func updateDynamicSize() {
    dynamicSize = calculateFrameSize(size20, variantPercent30)
  }
}
