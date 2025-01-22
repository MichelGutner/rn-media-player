import React

@available(iOS 14.0, *)
@objc(RNVideoPlayer)
class RNVideoPlayer: RCTViewManager {
  @objc override func view() -> (RNMediaPlayerView) {
    return RNMediaPlayerView()
  }
  
  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}




