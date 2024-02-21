//
//  ModalOptionsView.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 20/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct ModalOptionsView : View {
  var data: [HashbleItem] = []
  var onSelected: (Any) -> Void
  
  @State var selectedItem = ""
  
  var body: some View {
    ForEach(data, id: \.self) { [self] item in
      Button(action: {
        //                        hidden()
        if let floatValue = Float(item.value ?? "")  {
          onSelected(floatValue)
        } else {
          onSelected(item.value as Any)
        }
        selectedItem = item.name
      }) {
        
        Group {
          if let enabled = item.enabled, enabled {
            HStack {
              ZStack {
                Circle().stroke(Color.primary, lineWidth: 1).frame(width: 12, height: 12)
                if selectedItem == item.name {
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
            .fixedSize(horizontal: true, vertical: true)
          }
        }
      }
      .disabled(selectedItem == item.name)
    }
    .frame(maxHeight: UIScreen.main.bounds.height / 2)
    .fixedSize(horizontal: true, vertical: true)
  }
}
