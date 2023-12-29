//
//  RNVideoPlayerLayers.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 25/11/23.
//

import UIKit

class CustomCAShapeLayers {
  public func createForwardShapeLayer(_ label: NSNumber?) -> CAShapeLayer {
    let svgPath = UIBezierPath()
    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius: 14, startAngle: 0, endAngle: 4.98, clockwise: true)
    svgPath.append(circlePath)
    
    let trianglePath = UIBezierPath()
    trianglePath.move(to: CGPoint(x: 9, y: 0))
    trianglePath.addLine(to: CGPoint(x: 1.5, y: 5))
    trianglePath.addLine(to: CGPoint(x: 1.5, y: -5))
    
    trianglePath.close()
    
    let triangleLayer = CAShapeLayer()
    triangleLayer.path = trianglePath.cgPath
    triangleLayer.fillColor = UIColor.white.cgColor
    triangleLayer.position = CGPoint(x: svgPath.bounds.midX, y: svgPath.bounds.minY)
    
    
    let numberLayer = CATextLayer()
    numberLayer.string = label?.stringValue
    numberLayer.foregroundColor = UIColor.white.cgColor
    numberLayer.alignmentMode = .center
    numberLayer.bounds.size = CGSize(width: 15, height: 15)
    numberLayer.position = CGPoint(x: svgPath.bounds.midX, y: svgPath.bounds.midY)
    numberLayer.fontSize = 12
    
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = svgPath.cgPath
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.strokeColor = UIColor.white.cgColor
    shapeLayer.lineWidth = 2
    
    shapeLayer.addSublayer(numberLayer)
    shapeLayer.addSublayer(triangleLayer)
    
    shapeLayer.frame.size = svgPath.getSize()
    return shapeLayer
  }
  
  public func createBackwardShapeLayer(_ label: NSNumber?) -> CAShapeLayer {
    let svgPath = UIBezierPath()
    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius: 14, startAngle: -1.8, endAngle: 3.1, clockwise: true)
    svgPath.append(circlePath)
    
    let trianglePath = UIBezierPath()
    trianglePath.move(to: CGPoint(x: 1.5, y: 0))
    trianglePath.addLine(to: CGPoint(x: 9, y: 5))
    trianglePath.addLine(to: CGPoint(x: 9, y: -5))
    trianglePath.close()
    
    let numberLayer = CATextLayer()
    numberLayer.string = label?.stringValue
    numberLayer.foregroundColor = UIColor.white.cgColor
    numberLayer.alignmentMode = .center
    numberLayer.bounds.size = CGSize(width: 15, height: 15)
    numberLayer.position = CGPoint(x: svgPath.bounds.midX, y: svgPath.bounds.midY)
    numberLayer.fontSize = 12
    
    let triangleLayer = CAShapeLayer()
    triangleLayer.path = trianglePath.cgPath
    triangleLayer.fillColor = UIColor.white.cgColor
    triangleLayer.position = CGPoint(x: svgPath.bounds.minX + trianglePath.bounds.width / 2, y: svgPath.bounds.minY)
    
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = svgPath.cgPath
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.strokeColor = UIColor.white.cgColor
    shapeLayer.lineWidth = 2
    
    shapeLayer.addSublayer(numberLayer)
    shapeLayer.addSublayer(triangleLayer)
    
    shapeLayer.frame.size = svgPath.getSize()
    return shapeLayer
  }
  
  private func createShapeLayerWithSvgPath(_ svgPath: UIBezierPath) -> CAShapeLayer {
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = svgPath.cgPath
    shapeLayer.fillColor = UIColor.white.cgColor
    shapeLayer.frame.size = svgPath.getSize()
    return shapeLayer
  }
}

extension UIBezierPath {
  func getSize() -> CGSize {
    let boundingBox = self.cgPath.boundingBox
    return CGSize(width: boundingBox.width, height: boundingBox.height)
  }
}


