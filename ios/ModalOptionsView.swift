//
//  ModalOptionsView.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 20/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct ModalOptionsView: View {
  var size: CGSize
  var data: [OptionSelection]
  var onSelected: (OptionSelection) -> Void
  var initialSelectedItem: String
  var selectedItem: String
  
  @State private var selected: String
  
  init(size: CGSize, data: [OptionSelection], onSelected: @escaping (OptionSelection) -> Void, initialSelectedItem: String, selectedItem: String) {
    self.size = size
    self.data = data
    self.onSelected = onSelected
    self.initialSelectedItem = initialSelectedItem
    self.selectedItem = selectedItem
    _selected = State(initialValue: selectedItem)
  }
  
  var body: some View {
    ScrollView {
      VStack {
        ForEach(data, id: \.self) { item in
          Button(action: {
            onSelected(item)
            selected = item.name
          }) {
            if item.enabled {
              HStack {
                ZStack {
                  Circle().stroke(Color.primary, lineWidth: 1).frame(width: 12, height: 12)
                  if selected == item.name {
                    Circle()
                      .fill(Color.primary)
                      .frame(width: 6, height: 6)
                  }
                }
                .padding(.trailing, 18)
                .fixedSize(horizontal: false, vertical: true)
                Text("\(item.name)").foregroundColor(.primary)
              }
              .frame(minWidth: UIScreen.main.bounds.width * 0.3, maxWidth: UIScreen.main.bounds.width * 0.6,alignment: .leading)
            
            }
          }
          .disabled(selected == item.name)
        }
      }
    }
    .frame(maxHeight: size.height * 0.7)
    .onAppear {
      if selected.isEmpty {
        selected = initialSelectedItem
      }
    }
    .fixedSize(horizontal: true, vertical: true)
  }
}
