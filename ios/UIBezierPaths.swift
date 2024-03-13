//
//  UIBezierPaths.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 12/03/24.
//

import Foundation
import UIKit

extension UIBezierPath {
  static func playLeftIcon(bounds: CGRect) -> UIBezierPath {
    let path = UIBezierPath()
    
    path.move(to:  CGPoint(x: bounds.minX + bounds.width * 0.2, y: bounds.minY))
    path.addLine(to: CGPoint(x: (bounds.midX * 0.8) + (bounds.width * 0.2), y: bounds.midY - bounds.height * 0.25))
    path.addLine(to: CGPoint(x: (bounds.midX * 0.8) + (bounds.width * 0.2), y: bounds.midY + bounds.height * 0.25))
    path.addLine(to: CGPoint(x: bounds.minX + bounds.width * 0.2, y: bounds.maxY))
    
    return path
  }
  
  
  static func playRightIcon(bounds: CGRect) -> UIBezierPath {
    let path = UIBezierPath()
    
    path.move(to: CGPoint(x: (bounds.midX * 0.8) + (bounds.width * 0.2), y: bounds.midY - bounds.height * 0.25))
    path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
    path.addLine(to: CGPoint(x: (bounds.midX * 0.8) + (bounds.width * 0.2), y:  bounds.midY + bounds.height * 0.25))
    path.close()
    
    return path
  }
  
  static func pauseLeftIcon(bounds: CGRect) -> UIBezierPath {
    let path = UIBezierPath(rect: CGRect(x: bounds.minX + bounds.width * 0.2, y: bounds.minY, width: bounds.width * 0.2, height: bounds.height))
    path.close()
    return path
  }
  
  static func pauseRightIcon(bounds: CGRect) -> UIBezierPath {
    let path = UIBezierPath(rect: CGRect(x: bounds.midX + bounds.width * 0.15, y: bounds.minY, width: bounds.width * 0.2, height: bounds.height))
    path.close()
    return path
  }
}
