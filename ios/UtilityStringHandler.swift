//
//  File.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 08/12/23.
//

public func hexStringToUIColor(hexColor: String) -> UIColor {
  let stringScanner = Scanner(string: hexColor)
  
  if(hexColor.hasPrefix("#")) {
    stringScanner.scanLocation = 1
  }
  
  var color: UInt32 = 0
  stringScanner.scanHexInt32(&color)
  
  let r = CGFloat(Int(color >> 16) & 0x000000FF)
  let g = CGFloat(Int(color >> 8) & 0x000000FF)
  let b = CGFloat(Int(color) & 0x000000FF)
  
  return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
}

public func stringFromTimeInterval(interval: TimeInterval) -> String {
  let interval = Int(interval)
  let seconds = interval % 60
  let minutes = (interval / 60) % 60
  let hours = (interval / 3600)
  return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}


