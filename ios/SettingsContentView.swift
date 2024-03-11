//
//  SettingsModalView.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 20/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct SettingsContentView: View {
  var settingsData: [HashableData]
  var onSettingSelected: (String) -> Void
  
  init(settingsData: [HashableData], onSettingSelected: @escaping (String) -> Void) {
    self.settingsData = settingsData
    self.onSettingSelected = onSettingSelected
  }
  
  var body: some View {
    ForEach(settingsData, id: \.self) { setting in
      if setting.enabled {
        Button(action: {
          onSettingSelected(setting.value)
        }) {
          HStack {
            if let imageType = SettingsOption(rawValue: setting.value),
               let imageName = settingsImage(for: imageType) {
              Image(systemName: imageName)
                .foregroundColor(.primary)
            }
            
            Text(setting.name)
              .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.forward")
              .foregroundColor(.primary)
          }
          .padding(.bottom, 18)
          .padding(.leading, 8)
          .padding(.trailing, 8)
          .frame(minWidth: UIScreen.main.bounds.width * 0.5, maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
        }
      }
    }
    .fixedSize(horizontal: false, vertical: true)
  }
  
  private func settingsImage(for optionType: SettingsOption) -> String? {
    switch optionType {
    case .qualities:
      return "slider.horizontal.3"
    case .speeds:
      return "timer"
    case .moreOptions:
      return "gear"
    }
  }
}
