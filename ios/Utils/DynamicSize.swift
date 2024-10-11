//
//  UtilityDynamicSize.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 14/01/24.
//

import Foundation

public func calculateSizeByWidth(_ size: CGFloat, _ fontVariant: CGFloat) -> CGFloat {
  return round(size + (round((UIScreen.main.bounds.width / 375) * size) - size) * fontVariant)
}

public func calculateSizeByWidthWithoutRounded(_ size: CGFloat, _ fontVariant: CGFloat) -> CGFloat {
  return (size + (((UIScreen.main.bounds.width / 375) * size) - size) * fontVariant)
}
