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
      let isPortrait = _window?.windowScene?.interfaceOrientation.isPortrait == true
      fullScreenLayer = shapeLayerByOrientation(isPortrait)
      let orientations: UIInterfaceOrientationMask = isPortrait ? .landscape : .portrait
      _window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientations)) { error in
        print(error.localizedDescription)
      }
    } else {
      let orientation: UIInterfaceOrientation
      if UIInterfaceOrientation.portrait == .portrait {
        orientation = .landscapeRight
      } else {
        orientation = .portrait
      }
      fullScreenLayer = shapeLayerByOrientation(orientation == .portrait)
      UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }
    
    let transition = CATransition()
    transition.type = .reveal
    transition.duration = 1.0
    
    _view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    _view.layer.sublayers?.forEach { $0.add(transition, forKey: nil) }
    _view.layer.addSublayer(fullScreenLayer)
  }
  
  func shapeLayerByOrientation(_ isPortrait: Bool) -> CAShapeLayer {
    return isPortrait ? _shapeLayer.createExitFullScreenShapeLayer() : _shapeLayer.createFullScreenShapeLayer()
  }
}
