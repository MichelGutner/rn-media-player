//
//  SettingsModalView.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 20/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct SettingsModalView: View {
  var settingsData: [HashableItem] = []
  var onSettingSelected: (String) -> Void
  
  init(settingsData: [HashableItem], onSettingSelected: @escaping (String) -> Void) {
    self.settingsData = settingsData
    self.onSettingSelected = onSettingSelected
  }
  
  var body: some View {
    ForEach(settingsData, id: \.self) { setting in
      let imageType = ESettingsOptions(rawValue: setting.value!)
      let imageName = settingsImage(for: imageType ?? .qualities)
      
      Group {
        if let isEnabled = setting.enabled, isEnabled {
          Button(action: {
            onSettingSelected(setting.value!)
          }) {
            HStack {
              Image(systemName: imageName)
                .foregroundColor(.primary)
              
              Text(setting.name)
                .padding(.leading, 18)
                .padding(.trailing, 18)
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
    }
    .fixedSize(horizontal: false, vertical: true)
  }
  
  private func settingsImage(for optionType: ESettingsOptions) -> String {
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
