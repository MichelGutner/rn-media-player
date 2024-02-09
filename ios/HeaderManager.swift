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
  var title: String
  var onTapSettings: () -> Void
  @State private var isSettingsTapped: Bool = false
  
  @State private var dynamicSize = calculateFrameSize(size20, variantPercent30)
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
                Group {
                  Spacer()
                  if !isSettingsTapped {
                    Text(title)
                      .font(.system(size: dynamicTitleSize))
                      .foregroundColor(.white)
                      .frame(maxWidth: UIScreen.main.bounds.width * variantPercent60)
                      .lineLimit(1)
                      .padding(.top, -20)
                  }
                  Spacer()
                }
        Spacer()
        SettingsManager(onTap: {
          onTapSettings()
          isSettingsTapped.toggle()
        }, size: dynamicSize, isTapped: isSettingsTapped)
      }
      
      
    }
    .padding(.leading, 20)
    .padding(.trailing, 20)
    .padding(.top, 16)
    .onAppear {
      NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: .main) { _ in
        updateDynamicSize()
        updateTitleDynamicSize()
      }
    }
  }
  
  private func updateDynamicSize() {
    dynamicSize = calculateFrameSize(size20, variantPercent30)
  }
  private func updateTitleDynamicSize() {
    dynamicTitleSize = calculateFrameSize(size14, variantPercent20)
  }
}
