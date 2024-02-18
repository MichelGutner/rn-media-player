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
struct ModalManager<Content: View>: View {
  var data: [[String: String]]
  var title: String
  var onAppear: () -> Void
  var onDisappear: () -> Void
  var completionHandler: (() -> Void)
  var children: () -> Content
  
  @Binding var isOpened: Bool
  @State var offset = UIScreen.main.bounds.height
  
  var body: some View {
    ZStack {
      Color(.black).opacity(0.1).onTapGesture {
        hidden()
      }.edgesIgnoringSafeArea(Edge.Set.all)
      
      VStack(alignment: .leading, spacing: calculateFrameSize(size16, variantPercent20)) {
        HStack(alignment: .center) {
          Spacer()
          Rectangle().frame(width: UIScreen.main.bounds.width * 0.07, height: 4).foregroundColor(Color.white)
          Spacer()
          Button (action: {
            hidden()
          }) {
            Image(systemName: "xmark").foregroundColor(Color.white)
          }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
        HStack {
          Text(title)
            .foregroundColor(.white)
          Spacer()
        }
        children()
      }
      .fixedSize(horizontal: true, vertical: true)
      .padding(.leading)
      .padding(.trailing)
      .padding(.bottom)
      .background(Color.gray.opacity(0.8))
      .cornerRadius(12)
      .shadow(color: Color.white, radius: 0.4, x: 0.1, y: 0.1)
      .offset(x: 0, y: offset)
      .onAppear {
        if isOpened {
          withAnimation(.interactiveSpring(dampingFraction: 1.0)) {
            
            self.offset = 0
            isOpened = false
            onAppear()
          }
        }
      }
      .onDisappear {
        onDisappear()
      }
      
    }
  }
  
  public func hidden() {
    withAnimation(.interactiveSpring(dampingFraction: 1.0)) {
      offset = UIScreen.main.bounds.height
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
        completionHandler()
    })
  }
}
