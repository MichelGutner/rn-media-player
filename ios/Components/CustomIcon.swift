//
//  CustomIcon.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 13/03/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct CustomIcon : View {
  var name: String
  
  init(_ name: String) {
    self.name = name
  }
  
  var body: some View {
    let iconSize = calculateSizeByWidth(StandardSizes.small18, VariantPercent.p20)
    
    Image(systemName: name)
      .font(.system(size: iconSize))
      .foregroundColor(.white)
      .padding(8)
  }
}
