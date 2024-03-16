//
//  Color.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 14/03/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
extension Color {
    init(uiColor: UIColor) {
        let components = uiColor.cgColor.components
        let red = components?[0] ?? 1
        let green = components?.count ?? 0 > 1 ? components![1] : 1
        let blue = components?.count ?? 0 > 2 ? components![2] : 1
      let alpha = uiColor.cgColor.alpha
        self.init(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
}
