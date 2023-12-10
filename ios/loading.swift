//
//  loading.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 10/12/23.
//

import Foundation
import UIKit

class Loading {
  private var _view: UIView
  
  init(_ view: UIView) {
    self._view = view
  }
  
  var indicator: UIActivityIndicatorView!
  var loadingSize = CGSize(width: 40, height: 40)
  
  public func showLoading() {
    if #available(iOS 13.0, *) {
        indicator = UIActivityIndicatorView(style: .large)
        indicator.center = _view.center
    } else {
        // Fallback on earlier versions
        indicator = UIActivityIndicatorView(style: .whiteLarge)
      indicator.frame.origin = _view.bounds.origin
      indicator.frame.size = loadingSize
    }
    indicator.hidesWhenStopped = true
    _view.addSubview(indicator)
    
    indicator?.startAnimating()
    _view.isUserInteractionEnabled = false
  }
  
  public func hideLoading() {
    _view.layer.sublayers?.forEach {$0.removeFromSuperlayer()}
    indicator?.stopAnimating()
    _view.isUserInteractionEnabled = true
    _view.isHidden = true
  }
}
