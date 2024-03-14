//
//  ModalOptionsView.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 20/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct OptionsContentView: View {
  var size: CGSize
  var data: [HashableModalContent]
  var onSelected: (HashableModalContent) -> Void
  var initialSelectedItem: String
  var selectedItem: String
  
  @State private var selected: String
  
  init(size: CGSize, data: [HashableModalContent], onSelected: @escaping (HashableModalContent) -> Void, initialSelectedItem: String, selectedItem: String) {
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
                  Circle().stroke(selected == item.name ? Color.primary : Color.gray, lineWidth: 1).frame(width: 12, height: 12)
                  if selected == item.name {
                    Circle()
                      .fill(Color.primary)
                      .frame(width: 6, height: 6)
                  }
                }
                .padding(.trailing, 18)
                .fixedSize(horizontal: false, vertical: true)
                Text("\(item.name)").foregroundColor(selected == item.name ? Color.primary : Color.gray)
                Spacer()
              }
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
