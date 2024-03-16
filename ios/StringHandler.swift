//
//  File.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 08/12/23.
//

public func transformStringIntoUIColor(color: String?) -> UIColor? {
  guard let colorToTransform = color else {
    return nil
  }
  
  if (colorToTransform.hasPrefix("rgba")) {
    return transformRgbaIntoUIColor(color: colorToTransform)!
  }
  
  let stringScanner = Scanner(string: colorToTransform)
  
  if(colorToTransform.hasPrefix("#")) {
    stringScanner.scanLocation = 1
  }
  
  var color: UInt32 = 0
  stringScanner.scanHexInt32(&color)
  
  let r = CGFloat(Int(color >> 16) & 0x000000FF)
  let g = CGFloat(Int(color >> 8) & 0x000000FF)
  let b = CGFloat(Int(color) & 0x000000FF)
  
  return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
}

private func transformRgbaIntoUIColor(color hexColor: String) -> UIColor? {
  if let index = hexColor.index(hexColor.startIndex, offsetBy: 4, limitedBy: hexColor.endIndex) {
    let removeAllSpecialCharacters = hexColor[index...]
    let numericData = removeAllSpecialCharacters.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
    let red = Float(numericData[1]) ?? 255.0
    let green = Float(numericData[2]) ?? 255.0
    let blue = Float(numericData[3]) ?? 255.0
    let alpha = Float(numericData[4]) ?? 1
    
    return UIColor(red: CGFloat(red / 255.0), green: CGFloat(green / 255.0), blue: CGFloat(blue / 255.0), alpha: CGFloat(alpha))
  } else {
    print("error: Invalid color")
    return .white
  }
}


public func stringFromTimeInterval(interval: TimeInterval = 0) -> String {
  guard !interval.isInfinite, !interval.isNaN else {
    return String(format: "%02d:%02d", 0, 0)
  }
  
  let interval = Int(interval)
  let seconds = interval % 60
  let minutes = (interval / 60) % 60
  let hours = (interval / 3600)
  
  if hours > 0 {
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }
  
  return String(format: "%02d:%02d", minutes, seconds)
}
