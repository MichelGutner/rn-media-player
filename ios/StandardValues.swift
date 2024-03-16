//
//  VideoSizes.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 07/01/24.
//

import Foundation

struct StandardSizes {
  // smalls
  static let small8: CGFloat = 8
  static let small16: CGFloat = 16
  static let small14: CGFloat = 14
  static let small18: CGFloat = 18
  static let small20: CGFloat = 20
  
  // medium 21 - 40
  static let medium24: CGFloat = 24
  static let medium22: CGFloat = 22
  static let medium30: CGFloat = 30
  
  // larges 41 - 80
  static let large55: CGFloat = 55
  
  // extra large
  static let extraLarge100: CGFloat = 100
  static let extraLarge200: CGFloat = 200
  
  // --- identified sizes
  static let playbackControler: CGFloat = 25
  static let seekerViewMinHeight: CGFloat = 3
  static let seekerViewMaxHeight: CGFloat = 6
}

struct AnimationDuration {
  static let s035: CGFloat = 0.35
  static let s020: CGFloat = 0.20
}

struct VariantPercent {
  static let p10 = 0.1
  static let p20 = 0.2
  static let p30 = 0.3
  static let p40 = 0.4
  static let p60 = 0.6
  static let p80 = 0.8
}

struct CornerRadius {
  static let small: CGFloat = 8
  static let medium: CGFloat = 16
  static let large: CGFloat = 30
  static let extraLarge: CGFloat = 60
  static let infinity: CGFloat = .infinity
}
