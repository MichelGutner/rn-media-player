//
//  RctDirectEvents.swift
//  Pods
//
//  Created by Michel Gutner on 22/01/25.
//

public enum Dispatcher {
  case onMenuItemSelected
  case onMediaPlayPause
  case onMediaError
  case onMediaBuffering
  case onMediaSeekBar
  case onMediaReady
  case onMediaCompleted
  case onFullScreenStateChanged
  case onMediaBufferCompleted
  case onMediaPinchZoom
}

public protocol RRCTPropsViewDelegate: AnyObject {
  func onThumbnails(_ url: String)
  func onReplaceMediaUrl(_ url: String)
  func onSource(_ source: NSDictionary?)
  func onEntersFullScreenWhenPlaybackBegins(_ didEnterFullscreen: Bool)
  func onAutoPlay(_ didPlay: Bool)
  func onRate(_ rate: Float)
}

class RCTPropsView : UIView {
  open weak var rctPropsViewDelegate: RRCTPropsViewDelegate?
  
  @objc private var onMenuItemSelected: RCTBubblingEventBlock?
  @objc private var onMediaPlayPause: RCTDirectEventBlock?
  @objc private var onMediaError: RCTDirectEventBlock?
  @objc private var onMediaBuffering: RCTBubblingEventBlock?
  @objc private var onMediaSeekBar: RCTDirectEventBlock?
  @objc private var onMediaReady: RCTBubblingEventBlock?
  @objc private var onMediaCompleted: RCTBubblingEventBlock?
  @objc private var onFullScreenStateChanged: RCTDirectEventBlock?
  @objc private var onMediaBufferCompleted: RCTDirectEventBlock?
  @objc private var onMediaPinchZoom: RCTDirectEventBlock?
  
  @objc private var entersFullScreenWhenPlaybackBegins: Bool = false
  @objc private var autoPlay: Bool = false
  
  @objc private var onMediaRouter: RCTDirectEventBlock?
  
  func sendEvent(_ dispatcher: Dispatcher, _ receivedValue: Any) {
    switch dispatcher {
    case .onMenuItemSelected:
      let values = receivedValue as! (String, Any)
      onMenuItemSelected?(["name": values.0, "value": values.1])
    case .onMediaPlayPause:
      onMediaPlayPause?(["isPlaying": receivedValue])
    case .onMediaError:
      let error = receivedValue as! NSError
      onMediaError?([
        "domain": error.domain,
        "code": error.code,
        "userInfo": [
          "description": error.userInfo[NSLocalizedDescriptionKey],
          "failureReason": error.userInfo[NSLocalizedFailureReasonErrorKey],
          "fixSuggestion": error.userInfo[NSLocalizedRecoverySuggestionErrorKey]
        ]
      ])
    case .onMediaBuffering:
      onMediaBuffering?(receivedValue as? [AnyHashable : Any])
    case .onMediaSeekBar:
      onMediaSeekBar?(receivedValue as? [AnyHashable : Any])
    case .onMediaReady:
      if let receivedDict = receivedValue as? [String: Any],
         let isLoaded = receivedDict["loaded"] as? Bool {

        if entersFullScreenWhenPlaybackBegins, isLoaded {
          self.rctPropsViewDelegate?.onEntersFullScreenWhenPlaybackBegins(entersFullScreenWhenPlaybackBegins)
        }
        
        if autoPlay, isLoaded {
          self.rctPropsViewDelegate?.onAutoPlay(true)
        }
      }
      onMediaReady?(receivedValue as? [AnyHashable : Any])
    case .onMediaCompleted:
      onMediaCompleted?(receivedValue as? [AnyHashable : Any])
    case .onFullScreenStateChanged:
      onFullScreenStateChanged?(receivedValue as? [AnyHashable : Any])
    case .onMediaBufferCompleted:
      onMediaBufferCompleted?(receivedValue as? [AnyHashable : Any])
    case .onMediaPinchZoom:
      onMediaPinchZoom?(receivedValue as? [AnyHashable : Any])
    }
  }
  
  @objc private var thumbnails: NSDictionary? = [:] {
    didSet {
      if thumbnails != nil {
        guard let thumbnails,
              let enabled = thumbnails["isEnabled"] as? Bool,
              enabled,
              let url = thumbnails["sourceUrl"] as? String
        else { return }
        self.rctPropsViewDelegate?.onThumbnails(url)
      }
    }
  }
  
  @objc private var replaceMediaUrl: String? = nil {
    didSet {
      guard let validUrl = replaceMediaUrl, !validUrl.isEmpty else { return }
      self.rctPropsViewDelegate?.onReplaceMediaUrl(validUrl)
    }
  }
  
  @objc private var source: NSDictionary? = [:] {
    didSet {
      self.rctPropsViewDelegate?.onSource(source)
    }
  }
  
  @objc var rate: Float = 1.0 {
    didSet {
      if !rate.isNaN || oldValue != rate {
        self.rctPropsViewDelegate?.onRate(rate)
      }
    }
  }

}
