//
//  loading.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 10/12/23.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
protocol LoadingProtocol: AnyObject {
    func show()
    func hide()
}

@available(iOS 13.0, *)
class Loading: LoadingProtocol {
  private var _view: UIView
  
  init(_ view: UIView) {
    self._view = view
  }
  
  var indicator: UIActivityIndicatorView!
  
  public func show() {
    indicator = UIActivityIndicatorView(style: .large)
    indicator.color = .white
    indicator.center = _view.center
    indicator.reactZIndex = 3
    print("SHOWED")
    indicator.hidesWhenStopped = true
    _view.addSubview(indicator)
    
    indicator?.startAnimating()
    _view.isUserInteractionEnabled = false
  }
  
  public func hide() {
    print("HIDED")
    _view.layer.sublayers?.forEach {$0.removeFromSuperlayer()}
    indicator?.stopAnimating()
    _view.isUserInteractionEnabled = true
    _view.isHidden = true
  }
}
