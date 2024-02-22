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
  var data: [HashableItem]
  var onSelected: (HashableItem) -> Void
  var initialSelectedItem: String
  var selectedItem: String
  
  @State private var selected: String
  
  init(data: [HashableItem], onSelected: @escaping (HashableItem) -> Void, initialSelectedItem: String, selectedItem: String) {
    self.data = data
    self.onSelected = onSelected
    self.initialSelectedItem = initialSelectedItem
    self.selectedItem = selectedItem
    _selected = State(initialValue: selectedItem)
  }
  
  var body: some View {
    VStack {
      ForEach(data, id: \.self) { item in
        Button(action: {
          onSelected(item)
          selected = item.name
        }) {
          if let enabled = item.enabled, enabled {
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
            .frame(minWidth: UIScreen.main.bounds.width * 0.3, maxWidth: UIScreen.main.bounds.width * 0.6, alignment: .leading)
          }
        }
        .disabled(selected == item.name)
      }
    }
    .onAppear {
      if selected.isEmpty {
        selected = initialSelectedItem
      }
    }
    .frame(maxHeight: UIScreen.main.bounds.height / 2)
    .fixedSize(horizontal: true, vertical: true)
  }
}
