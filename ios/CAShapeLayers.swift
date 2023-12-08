//
//  RNVideoPlayerLayers.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 25/11/23.
//

import UIKit

class CAShapeLayers {
  public func fullScreen() -> CAShapeLayer {
    let shapeLayer = CAShapeLayer()
    let svgPath = UIBezierPath()
    
    // leftTop
    svgPath.move(to: CGPoint(x: 4, y: 4))
    svgPath.addLine(to: CGPoint(x: 6, y: 4))
    svgPath.addLine(to: CGPoint(x: 6, y: 10))
    svgPath.addLine(to: CGPoint(x: 4, y: 10))
    
    svgPath.move(to: CGPoint(x: 4, y: 4))
    svgPath.addLine(to: CGPoint(x: 10, y: 4))
    svgPath.addLine(to: CGPoint(x: 10, y: 6))
    svgPath.addLine(to: CGPoint(x: 4, y: 6))
    
    // rightTop
    svgPath.move(to: CGPoint(x: 17, y: 4))
    svgPath.addLine(to: CGPoint(x: 19, y: 4))
    svgPath.addLine(to: CGPoint(x: 19, y: 10))
    svgPath.addLine(to: CGPoint(x: 17, y: 10))
    
    svgPath.move(to: CGPoint(x: 13, y: 4))
    svgPath.addLine(to: CGPoint(x: 17, y: 4))
    svgPath.addLine(to: CGPoint(x: 17, y: 6))
    svgPath.addLine(to: CGPoint(x: 13, y: 6))
    
    // leftBottom
    svgPath.move(to: CGPoint(x: 4, y: 13))
    svgPath.addLine(to: CGPoint(x: 6, y: 13))
    svgPath.addLine(to: CGPoint(x: 6, y: 19))
    svgPath.addLine(to: CGPoint(x: 4, y: 19))
    
    svgPath.move(to: CGPoint(x: 4, y: 17))
    svgPath.addLine(to: CGPoint(x: 10, y: 17))
    svgPath.addLine(to: CGPoint(x: 10, y: 19))
    svgPath.addLine(to: CGPoint(x: 4, y: 19))
    
    // rightBottom
    svgPath.move(to: CGPoint(x: 17, y: 13))
    svgPath.addLine(to: CGPoint(x: 19, y: 13))
    svgPath.addLine(to: CGPoint(x: 19, y: 19))
    svgPath.addLine(to: CGPoint(x: 17, y: 19))
    
    svgPath.move(to: CGPoint(x: 13, y: 17))
    svgPath.addLine(to: CGPoint(x: 19, y: 17))
    svgPath.addLine(to: CGPoint(x: 19, y: 19))
    svgPath.addLine(to: CGPoint(x: 13, y: 19))
    svgPath.close()
    
    
    
    shapeLayer.path = svgPath.cgPath
    shapeLayer.fillColor = UIColor.white.cgColor
    
    return shapeLayer
  }
  
  public func exitFullScreen() -> CAShapeLayer {
    let svgPath = UIBezierPath()
    
    // --- leftTop
    svgPath.move(to: CGPoint(x: 8, y: 4))
    svgPath.addLine(to: CGPoint(x: 10, y: 4))
    svgPath.addLine(to: CGPoint(x: 10, y: 10))
    svgPath.addLine(to: CGPoint(x: 8, y: 10))
    svgPath.close()
    
    svgPath.move(to: CGPoint(x: 4, y: 8))
    svgPath.addLine(to: CGPoint(x: 10, y: 8))
    svgPath.addLine(to: CGPoint(x: 10, y: 10))
    svgPath.addLine(to: CGPoint(x: 4, y: 10))
    svgPath.close()
    
    //---- rightTop
    svgPath.move(to: CGPoint(x: 15, y: 4))
    svgPath.addLine(to: CGPoint(x: 17, y: 4))
    svgPath.addLine(to: CGPoint(x: 17, y: 10))
    svgPath.addLine(to: CGPoint(x: 15, y: 10))
    svgPath.close()
    
    svgPath.move(to: CGPoint(x: 15, y: 8))
    svgPath.addLine(to: CGPoint(x: 21, y: 8))
    svgPath.addLine(to: CGPoint(x: 21, y: 10))
    svgPath.addLine(to: CGPoint(x: 15, y: 10))
    svgPath.close()
    
    // *----- leftBottom
    svgPath.move(to: CGPoint(x: 8, y: 15))
    svgPath.addLine(to: CGPoint(x: 10, y: 15))
    svgPath.addLine(to: CGPoint(x: 10, y: 21))
    svgPath.addLine(to: CGPoint(x: 8, y: 21))
    svgPath.close()
    
    svgPath.move(to: CGPoint(x: 4, y: 15))
    svgPath.addLine(to: CGPoint(x: 10, y: 15))
    svgPath.addLine(to: CGPoint(x: 10, y: 17))
    svgPath.addLine(to: CGPoint(x: 4, y: 17))
    svgPath.close()
    
    //----- rightBottom
    svgPath.move(to: CGPoint(x: 15, y: 15))
    svgPath.addLine(to: CGPoint(x: 17, y: 15))
    svgPath.addLine(to: CGPoint(x: 17, y: 21))
    svgPath.addLine(to: CGPoint(x: 15, y: 21))
    svgPath.close()
    
    svgPath.move(to: CGPoint(x: 15, y: 15))
    svgPath.addLine(to: CGPoint(x: 21, y: 15))
    svgPath.addLine(to: CGPoint(x: 21, y: 17))
    svgPath.addLine(to: CGPoint(x: 15, y: 17))
    svgPath.close()
    
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = svgPath.cgPath
    shapeLayer.fillColor = UIColor.white.cgColor
    
    return shapeLayer
  }
  
  public func forward(_ label: NSNumber?) -> CAShapeLayer {
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
    
    shapeLayer.frame.size = CGSize(width: svgPath.bounds.width, height: svgPath.bounds.height)
    return shapeLayer
  }
  
  public func backward(_ label: NSNumber?) -> CAShapeLayer {
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
    
    shapeLayer.frame.size = CGSize(width: svgPath.bounds.width, height: svgPath.bounds.height)
    return shapeLayer
  }
  
  public func pause() -> CAShapeLayer {
    let svgPath = UIBezierPath()
    
    svgPath.move(to: CGPoint(x: -15, y: 0))
    svgPath.addLine(to: CGPoint(x: -5, y: 0))
    svgPath.addLine(to: CGPoint(x: -5, y: 32))
    svgPath.addLine(to: CGPoint(x: -15, y: 32))
    svgPath.close()
    
    svgPath.move(to: CGPoint(x: 5, y: 0))
    svgPath.addLine(to: CGPoint(x: 15, y: 0))
    svgPath.addLine(to: CGPoint(x: 15, y: 32))
    svgPath.addLine(to: CGPoint(x: 5, y: 32))
    svgPath.close()
    
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = svgPath.cgPath
    shapeLayer.fillColor = UIColor.white.cgColor
    
    shapeLayer.frame.size = CGSize(width: svgPath.bounds.width, height: svgPath.bounds.height)
    
    return shapeLayer
  }
  
  public func play() -> CAShapeLayer {
    let svgPath = UIBezierPath()
    svgPath.move(to: CGPoint(x: 0, y: 0))
    svgPath.addLine(to: CGPoint(x: 20, y: 15))
    svgPath.addLine(to: CGPoint(x: 0, y: 32))
    svgPath.close()
    
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = svgPath.cgPath
    shapeLayer.fillColor = UIColor.white.cgColor
    
    shapeLayer.frame.size = CGSize(width: svgPath.bounds.width, height: svgPath.bounds.height)
    return shapeLayer
  }
}
