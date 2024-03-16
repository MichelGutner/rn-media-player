//
//  ModalMenuOptionsLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 28/01/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct CustomLoading: View {
  let config: NSDictionary?
  @State var isLoading : Bool = false
  @State var size = calculateSizeByWidth(StandardSizes.medium24, VariantPercent.p20)
  var body: some View {
    
    let loadingColor = config?["color"]
    let color = Color(transformStringIntoUIColor(color: loadingColor as? String) ?? .white)
    
    
    ZStack {
      Circle().trim(from: 0, to: 0.8)
        .stroke(color, lineWidth: 3)
        .frame(width: size, height: size, alignment: .center)
        .rotationEffect(Angle(degrees: isLoading ? 0 : 360))
      
        .onAppear() {
          
          withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            isLoading.toggle()
          }
        }
    }
  }
  
  private func updateDynamicSize() {
    size = calculateSizeByWidth(StandardSizes.medium30, VariantPercent.p20)
  }
  
}
