//
//  VideoSizes.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 07/01/24.
//

import Foundation

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
