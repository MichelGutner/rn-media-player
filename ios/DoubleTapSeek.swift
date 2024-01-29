//
//  DoubleTapSeek.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 15/12/23.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct DoubleTapSeek: View {
  @State private var isTapped: Bool = false
  @State private var showArrows: [Bool] = [false, false, false]
  let position: CGPoint!
  var isForward: Bool = false
  var onTap: Bool = false
  
  var body: some View {
    ZStack {
      Rectangle()
        .foregroundColor(.clear)
        .overlay(
          GeometryReader { geometry in
            Circle()
              .fill(Color.black).opacity(0.4).position(position)
              .scaleEffect(1, anchor: .trailing)
          }
        )
        .overlay(
          GeometryReader { geometry in
            VStack(spacing: 10) {
              HStack(spacing: 0) {
                ForEach((0...2).reversed(), id: \.self) { index in
                  Image(systemName: "arrowtriangle.backward.fill")
                    .opacity(showArrows[index] ? 1 : 0.2)
                    .foregroundColor(.white)
                  
                }
              }
              .rotationEffect(.init(degrees: 0))
            }
            .contentShape(Rectangle())
            .position(position)
          }
        )
        .opacity(isTapped ? 1 : 0.1)
        .onTapGesture(count: 2) {
          withAnimation(.easeInOut(duration: 0.2)) {
            print("tapped", isTapped)
            self.isTapped.toggle()
            self.showArrows[0] = true
          }
          
          withAnimation(.easeInOut(duration: 0.2).delay(0.2)) {
            self.showArrows[0] = false
            self.showArrows[1] = true
          }
          
          withAnimation(.easeInOut(duration: 0.2).delay(0.35)) {
            self.showArrows[1] = false
            self.showArrows[2] = true
          }
          
          withAnimation(.easeInOut(duration: 0.2).delay(0.5)) {
            self.showArrows[2] = false
            self.isTapped = false
          }
          
          
        }
    }
  }
}

