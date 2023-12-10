//
//  fullScreenButton.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 08/12/23.
//

import Foundation


class FullScreen {
  private var _window: UIWindow?
  private var fullScreenLayer = CAShapeLayer()
  private var _shapeLayer = CustomCAShapeLayers()
  private var _view = UIView()
  
  init(_window: UIWindow?, parentView: UIView) {
    self._window = _window
    _view = parentView
  }
  
  public func toggleFullScreen() {
    if #available(iOS 16.0, *) {
      if _window?.windowScene?.interfaceOrientation.isPortrait == true {
        fullScreenLayer = _shapeLayer.exitFullScreen()
        _window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
          print(error.localizedDescription)
        }
      } else {
        fullScreenLayer = _shapeLayer.fullScreen()
        _window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
          print(error.localizedDescription)
        }
        
      }
    } else {
      if UIInterfaceOrientation.portrait == .portrait {
        let orientation = UIInterfaceOrientation.landscapeRight.rawValue
        fullScreenLayer = _shapeLayer.exitFullScreen()
        UIDevice.current.setValue(orientation, forKey: "orientation")
      } else {
        fullScreenLayer = _shapeLayer.fullScreen()
        let orientation = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(orientation, forKey: "orientation")
      }
    }
    let transition = CATransition()
    transition.type = .reveal
    transition.duration = 1.0
    
    _view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    _view.layer.sublayers?.forEach { $0.add(transition, forKey: nil) }
    _view.layer.addSublayer(fullScreenLayer)
    
  }
}
