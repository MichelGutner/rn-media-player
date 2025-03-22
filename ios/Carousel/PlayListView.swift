//
//  CarouselView.swift
//  Pods
//
//  Created by Michel Gutner on 17/03/25.
//

import UIKit
import SwiftUI

struct PlayListItem {
  let title: String
  let image: UIImage?
  let url: String
  let startTime: Double
}

protocol PlayerListViewDelegate : AnyObject {
  func onSelectVideo(video: PlayListItem)
}

class PlayListView : UIView {
  private var overlayWindow: UIWindow? = nil
  private var playListData: [PlayListItem] = []
  weak var delegate: PlayerListViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    setupContent()
  }
  
  
  private func setupContent() {
    var playListView = PlayList(list: .constant(playListData))
    playListView.delegate = self
    let contentView = UIHostingController(rootView: playListView)
    contentView.view.backgroundColor = .clear
    contentView.view.frame = bounds
    addSubview(contentView.view)
  }
  
  func show() {
    if let currentWindow = UIApplication.currentWindow {
      let overlayWindow = UIWindow(frame: currentWindow.bounds)
      overlayWindow.windowScene = currentWindow.windowScene
      overlayWindow.rootViewController = UIViewController()
      
      overlayWindow.windowLevel = .alert + 101
      
      overlayWindow.isHidden = false
      
      self.overlayWindow = overlayWindow
      overlayWindow.addSubview(self)
      
      frame = currentWindow.bounds
      
      let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.prominent)
      let blurEffectView = UIVisualEffectView(effect: blurEffect)
      blurEffectView.frame = bounds
      blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      
      overlayWindow.backgroundColor = .clear
      overlayWindow.rootViewController?.view.addSubview(blurEffectView)
    }
  }
  
  func hide() {
    overlayWindow?.isHidden = true
    overlayWindow?.removeFromSuperview()
    overlayWindow = nil
  }
  
  func populatePlayList(with data: NSArray?) {
    data?.forEach {
      if let item = $0 as? NSDictionary {
        guard let title = item["title"] as? String,
              let url = item["url"] as? String,
              let thumbUrl = item["thumbUrl"] as? String,
              let startTime = item["startTime"] as? Double else { return }
        
        loadImage(url: thumbUrl) { [self] image in
                let newItem = PlayListItem(title: title, image: image, url: url, startTime: startTime)
                playListData.append(newItem)
            }
      }
    }
  }
  
  private func loadImage(url: String, completionHandler: @escaping (UIImage?) -> Void) {
      guard let imageURL = URL(string: url) else {
          Debug.log("Invalid image URL: \(url)")
          completionHandler(nil)
          return
      }

      URLSession.shared.dataTask(with: imageURL) { data, _, error in
          if let error = error {
              Debug.log("Failed to load image: \(error.localizedDescription)")
              DispatchQueue.main.async { completionHandler(nil) }
              return
          }

          if let data = data, let loadedImage = UIImage(data: data) {
              DispatchQueue.main.async { completionHandler(loadedImage) }
          } else {
              DispatchQueue.main.async { completionHandler(nil) }
          }
      }.resume()
  }
}

extension PlayListView : PlayListDelegate {
  func didSelectVideo(with video: PlayListItem) {
    self.delegate?.onSelectVideo(video: video)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
      self.hide()
    })
  }
  
  func didClosePlayList() {
    self.hide()
  }
  
}

extension UIApplication {
  static var currentWindow : UIWindow? {
    return UIApplication.shared.connectedScenes
      .map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.first
  }
}
