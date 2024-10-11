//
//  FullScreen.swift
//  Pods
//
//  Created by Michel Gutner on 04/10/24.
//

import SwiftUI

@available(iOS 14.0, *)
struct FullScreen: View {
  @Binding var fullScreen: Bool
  var color: UIColor?
  var action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Circle()
        .fill(Color.black.opacity(0.4))
        .frame(width: 40, height: 40)
        .overlay(
          Image(systemName: fullScreen ? "arrow.down.forward.and.arrow.up.backward" : "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 14.0, weight: .bold))
            .foregroundColor(Color(uiColor: color ?? .white))
        )
    }
  }
}
