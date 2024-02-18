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
  var title: String
  @State private var isSettingsTapped: Bool = false
  
  @State private var dynamicSize = calculateFrameSize(size18, variantPercent30)
  @State private var dynamicTitleSize = calculateFrameSize(size14, variantPercent20)
  
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
        Text(title).font(.system(size: dynamicTitleSize)).foregroundColor(.white)
        Spacer()
        SettingsManager(onTap: {
          onTapSettings()
          isSettingsTapped.toggle()
        }, size: dynamicSize)
      }
      Spacer()
    }

    .padding(.top, 16)
    .onAppear {
      NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: .main) { _ in
        updateDynamicSize()
      }
    }
  }
  
  private func updateDynamicSize() {
    dynamicSize = calculateFrameSize(size18, variantPercent30)
    dynamicTitleSize = calculateFrameSize(size10, variantPercent20)
  }
}
