//
//  ModalLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 28/01/24.
//

import Foundation
import SwiftUI
import AVKit

@available(iOS 13.0, *)
struct ModalManager: View {
  let onClose: () -> ()
  let data: [[String: String]]
  let title: String
  var onSelected: (Any) -> Void
  var onAppear: () -> Void
  var initialSelected: String
  
  @Binding var isOpened: Bool
  @State var selected = ""
  @State var offset = UIScreen.main.bounds.height
  
  var body: some View {
    ZStack {
      Color(.black).opacity(0.1).onTapGesture {
        hidden()
      }.edgesIgnoringSafeArea(Edge.Set.all)
      
      VStack(alignment: .leading, spacing: calculateFrameSize(16, variantPercent20)) {
        HStack {
          Text(title).foregroundColor(.white).frame(width: UIScreen.main.bounds.width / 2, alignment: .leading)
          Button (action: {
            hidden()
          }) {
            Image(systemName: "xmark").foregroundColor(Color.white)
          }
        }.padding(.top)
        
        ScrollView(showsIndicators: false) {
          VStack {
            ForEach(data, id: \.self) { item in
              Button(action: {
                hidden()
                if let floatValue = Float(item["value"] ?? "")  {
                  onSelected(floatValue)
                } else {
                  onSelected(item["value"] as Any)
                }
                self.selected = item["name"]!
                
              }) {
                
                HStack {
                  ZStack {
                    Circle().stroke(Color.white, lineWidth: 1).frame(width: 12, height: 12)
                    
                    if self.selected == item["name"] {
                      Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                    }
                  }
                  .fixedSize(horizontal: false, vertical: true)
                  
                  Text("\(item["name"] ?? "")").foregroundColor(.white)
                }
                .frame(width: UIScreen.main.bounds.width / 2, alignment: .leading)
              }
              .disabled(selected == item["name"])
            }
          }
        }
      }
      .padding(.leading)
      .padding(.trailing)
      .padding(.bottom)
      .background(Color.black)
      .cornerRadius(12)
      .shadow(color: Color.white, radius: 0.4, x: 0.1, y: 0.1)
      .offset(x: 0, y: offset)
      .onAppear {
        if (self.selected.isEmpty) {
          self.selected = self.initialSelected
        }
        withAnimation(.interactiveSpring(dampingFraction: 1.0)) {
          self.offset = 0
          isOpened = false
          onAppear()
        }
      }
      
    }
    .padding()
  }
  
  public func hidden() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
      withAnimation(.interactiveSpring(dampingFraction: 2.0)) {
        offset = UIScreen.main.bounds.height
        onClose()
      }
    })
  }
}
