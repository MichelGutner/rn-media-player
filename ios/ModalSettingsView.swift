//
//  ModalSettingsView.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 20/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct ModalSettingsView : View {
  var data: [HashbleItem] = []
  var onSelected: (String) -> Void
  
  var body: some View {
    ForEach(data, id: \.self) { item in
      let imageType = ESettingsOptions(rawValue: item.value!)
      let imageName = settingsImageManager(imageType!)
      
      
      Group {
        if let enabled = item.enabled, enabled {
          Button(action: {
            onSelected(item.value!)
          }) {
            HStack {
              Image(systemName: imageName)
                .foregroundColor(.primary)
              
              Text(item.name)
                .padding(.leading, 18)
                .foregroundColor(.primary)
              
              Spacer()
              
              Image(systemName: "chevron.forward")
                .foregroundColor(.primary)
            }
            .padding(.bottom, 16)
            .frame(minWidth: UIScreen.main.bounds.width * 0.4, maxWidth: UIScreen.main.bounds.width * 0.6, alignment: .leading)
            .fixedSize(horizontal: true, vertical: true)
          }
        }
      }
    }
    .fixedSize(horizontal: true, vertical: true)
  }
  
  private func settingsImageManager(_ settingsOptionsType: ESettingsOptions) -> String {
    switch(settingsOptionsType) {
    case .quality:
      return "slider.horizontal.3"
    case .playbackSpeed:
      return "timer"
    case .moreOptions:
      return "gear"
    }
  }
}
