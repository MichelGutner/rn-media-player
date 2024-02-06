//
//  DownloadLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 05/02/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct IconLayoutManager : View {
  var imageName: String
  var onTap: () -> Void
  
  var body: some View {
    VStack {
      Button (action: {
        onTap()
        }) {
        Image(systemName: imageName)
          .foregroundColor(.white)
      }
    }
    .fixedSize(horizontal: true, vertical: true)
  }
}
