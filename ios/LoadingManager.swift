//
//  ModalMenuOptionsLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 28/01/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct LoadingManager: View {
  let config: NSDictionary?
  @State var isLoading : Bool = false
  @State var size = calculateFrameSize(size30, variantPercent20)
  var body: some View {
    
    let loadingColor = config?["color"]
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
          NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: .main) { _ in
            
          }
        }
    }
  }
  
  private func updateDynamicSize() {
    size = calculateFrameSize(size30, variantPercent20)
  }
  
}
