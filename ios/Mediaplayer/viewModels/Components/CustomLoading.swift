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
  @State private var rotationAngle: Double = 0
  @State private var glowEffect: Double = 1.0
  
  var body: some View {
    Circle().trim(from: 0, to: 0.7)
      .trim(from: 0.0, to: 1.0) // Abertura maior para um efeito dinâmico
      .stroke(Color(uiColor: color ?? .white).opacity(glowEffect), lineWidth: 4)
      .frame(width: size, height: size)
      .rotationEffect(Angle(degrees: rotationAngle))
      .onAppear {
          withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
              rotationAngle = 360
          }
          withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
              glowEffect = 0.3
          }
      }
  }
}
