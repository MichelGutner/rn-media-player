//
//  fullScreenButton.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 08/12/23.
//

import Foundation


class FullScreen {
  private var _window: UIWindow?
  private var _view = UIView()
  
  init(_window: UIWindow?, parentView: UIView) {
    self._window = _window
    _view = parentView
  }
  
  public func toggleFullScreen() {
    if #available(iOS 16.0, *) {
      let isPortrait = _window?.windowScene?.interfaceOrientation.isPortrait == true
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
      UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }
  
  }
}
