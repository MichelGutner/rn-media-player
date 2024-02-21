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
  @Environment(\.colorScheme) var colorScheme
  
  var onAppear: () -> Void
  var onDisappear: () -> Void
  var completionHandler: (() -> Void)
  var content: () -> Content

  @State var offset = UIScreen.main.bounds.height
  
  var body: some View {
    ZStack {
      Color(.black).opacity(0.001).onTapGesture {
        hidden()
      }
      .edgesIgnoringSafeArea(Edge.Set.all)
      
      VStack(alignment: .leading, spacing: calculateFrameSize(size16, variantPercent20)) {
        HStack(alignment: .center) {
          Spacer()
          Button (action: {
            hidden()
          }) {
            Image(systemName: "xmark").foregroundColor(Color.primary)
          }
        }
        .padding(.top, 12)
        ScrollView(showsIndicators: false) {
          VStack {
            content()
          }
          .padding(.trailing, 12)
          .padding(.leading, 12)
        }
      }
      .fixedSize(horizontal: true, vertical: true)
      .padding(.leading)
      .padding(.trailing)
      .padding(.bottom)
      .background(colorScheme == .light ? Color.white : Color.black)
      .cornerRadius(16)
      .shadow(color: Color.secondary, radius: 0.4, x: 0.1, y: 0.1)
      .offset(x: 0, y: offset)
      .onAppear {
        withAnimation(.interactiveSpring(dampingFraction: 1.0)) {
          self.offset = 0
          onAppear()
        }
      }
      .onDisappear {
        onDisappear()
      }
      
    }
  }
  
  public func hidden() {
    withAnimation(.interactiveSpring(dampingFraction: 1.3)) {
      offset = UIScreen.main.bounds.height
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
      completionHandler()
    })
  }
}
