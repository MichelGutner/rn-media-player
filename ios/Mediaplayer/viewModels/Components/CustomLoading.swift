//
//  ModalMenuOptionsLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 28/01/24.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
struct CustomLoading: View {
  let color: UIColor?
  @State var isLoading : Bool = false
  @State var size = calculateSizeByWidth(36, 0.2)
  var body: some View {
    Circle().trim(from: 0, to: 0.7)
      .stroke(Color(uiColor: color ?? .white), lineWidth: 3)
      .frame(width: size, height: size, alignment: .center)
      .rotationEffect(Angle(degrees: isLoading ? 0 : 360))
      .onAppear() {
        if (!isLoading) {
          withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            isLoading.toggle()
          }
        }
      }
  }
}
