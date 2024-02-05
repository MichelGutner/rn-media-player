//
//  ModalMenuOptionsLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 28/01/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct LoadingLayoutManager: View {
  let loadingColor: NSDictionary?
  @State var isLoading : Bool = false
  
  var body: some View {
    let size = calculateFrameSize(size22, variantPercent20)
    let loadingColor = loadingColor?["color"]
    let color = Color(transformStringIntoUIColor(color: loadingColor as? String))

    
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
  
}
