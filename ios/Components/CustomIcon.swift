//
//  CustomIcon.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 13/03/24.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
struct CustomIcon : View {
  var name: String
  var color: UIColor?
  
  init(_ name: String, color: UIColor?) {
    self.name = name
    self.color = color
  }
  
  var body: some View {
    let iconSize = calculateSizeByWidth(StandardSizes.small14, VariantPercent.p20)
    
    Image(systemName: name)
      .font(.system(size: iconSize))
      .foregroundColor(Color(uiColor: color ?? UIColor.white))
      .frame(width: iconSize * 2, height: iconSize * 2)
      .cornerRadius(CornerRadius.infinity)
  }
}
