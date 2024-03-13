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
  static let small18: CGFloat = 18
  static let small20: CGFloat = 20
  
  // medium 21 - 40
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
}

struct CorneRadious {
  static let c16: CGFloat = 16.0
}

public var size30 = CGFloat(30)
public var size18 = CGFloat(18)
public var size20 = CGFloat(20)
public var size22 = CGFloat(22)
public var size24 = CGFloat(24)
public var size8 = CGFloat(8)
public var size16 = CGFloat(16)
public var size50 = CGFloat(50)
public var size10 = CGFloat(10)
public var size14 = CGFloat(14)
public var size45 = CGFloat(45)
public var size55 = CGFloat(55)
public var size60 = CGFloat(60)
public var size90 = CGFloat(90)
public var size100 = CGFloat(100)


public var variantPercent10 = CGFloat(0.1)
public var variantPercent20 = CGFloat(0.2)
public var variantPercent30 = CGFloat(0.3)
public var variantPercent40 = CGFloat(0.4)
public var variantPercent60 = CGFloat(0.6)
public var variantPercent80 = CGFloat(0.8)

public var spacing20 = CGFloat(20)
public var spacing10 = CGFloat(10)

public var margin8 = calculateSizeByWidth(size8, variantPercent10)

public var size20v02 = calculateSizeByWidth(size24, variantPercent30)
public var dynamicSize18v30 = calculateSizeByWidth(size18, variantPercent30)
public var dynamicSize24v30 = calculateSizeByWidth(size24, variantPercent30)
