//
//  MediaPlayerView.swift
//  Pods
//
//  Created by Michel Gutner on 01/01/25.
//

import SwiftUI
import AVKit
import Combine

import AVKit
import UIKit
import AVFoundation
import SwiftUI

// Define um protocolo para padronizar o comportamento do ViewModel
protocol MediaPlayerObservableObjectProtocol: AnyObject {
    var sliderProgress: CGFloat { get set }
    var bufferingProgress: CGFloat { get set }
}

class MediaPlayerObservableObject: ObservableObject, MediaPlayerObservableObjectProtocol {
    @Published var bufferingProgress: CGFloat = 0.0
    @Published var sliderProgress: CGFloat = 0.0
    
    init(bufferingProgress: CGFloat = 0.0, sliderProgress: CGFloat = 0.0) {
        self.bufferingProgress = bufferingProgress
        self.sliderProgress = sliderProgress
    }
    
    func updateSliderProgress(to value: CGFloat) {
        sliderProgress = value
    }
    
    func updateBufferingProgress(to value: CGFloat) {
        bufferingProgress = value
    }
}
protocol MediaPlayerViewControllerProtocol {
  func configurePlayer(with source: NSDictionary?, playerAdapter: MediaPlayerAdapter?, autoPlay: Bool, onError: (Error) -> Void)
}

@available(iOS 14.0, *)
class MediaPlayerViewController: UIViewController, MediaPlayerViewControllerProtocol {
  private var mediaPlayerHC: UIHostingController<MediaPlayerControlsView>!
  private var player: AVPlayer?
  private var mediaPlayerAdapter: MediaPlayerAdapterImpl!
  private var viewModel = MediaPlayerObservableObject()
  
  private var autoPlay: Bool = false
  
  private var source: NSDictionary?

  private var isSeeking: Bool = false
  
  init() {
    super.init(nibName: nil, bundle: nil)
    setupMediaControls()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillLayoutSubviews() {
    mediaPlayerAdapter.updateAVLayerFrame(self.view.frame)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    mediaPlayerAdapter.release()
  }
  
  private func setupMediaControls() {
    mediaPlayerHC = UIHostingController(
      rootView: MediaPlayerControlsView(
        mediaSession: MediaSessionManager(),
        onTapFullscreen: { [weak self] in
          self?.toggleFullScreen()
        },
        menus: .constant([:]),
        viewModel: viewModel,
        onPlayPause: { [self] in
          if (self.mediaPlayerAdapter.isPlaying) {
            self.mediaPlayerAdapter.onPause()
          } else {
            self.mediaPlayerAdapter.onPlay()
          }
        }
      )
    )
    
  }
  
  private func attachControlsToParent(to controller: UIViewController) {
      if let mediaPlayerHC {
          if mediaPlayerHC.parent != controller {
              mediaPlayerHC.removeFromParent()

              mediaPlayerHC.view.backgroundColor = .clear
              controller.view.addSubview(mediaPlayerHC.view)
              mediaPlayerHC.didMove(toParent: self)

              mediaPlayerHC.view.translatesAutoresizingMaskIntoConstraints = false
              NSLayoutConstraint.activate([
                  mediaPlayerHC.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
                  mediaPlayerHC.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
                  mediaPlayerHC.view.topAnchor.constraint(equalTo: controller.view.topAnchor),
                  mediaPlayerHC.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
              ])
          }
      }
  }
  
  public func configurePlayer(
      with source: NSDictionary?,
      playerAdapter: MediaPlayerAdapter?,
      autoPlay: Bool,
      onError: (Error) -> Void
  ) {
    self.mediaPlayerAdapter = playerAdapter as? MediaPlayerAdapterImpl
    
    guard let urlString = source?["url"] as? String,
          let videoURL = URL(string: urlString) else {
      onError(NSError(domain: "MediaPlayerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid or missing video URL."]))
      return
    }
    
    let startTime = source?["startTime"] as? Double ?? 0
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
//      self.player = AVPlayer(url: videoURL)
//      self.player?.seek(to: CMTime(seconds: startTime, preferredTimescale: 1))
//      
//      if autoPlay {
//        self.player?.play()
//      }
      let asset = MediaPlayerManager.asset(from: .init(url: videoURL))
      self.mediaPlayerAdapter.initializeMediaPlayer(asset: asset)
      self.mediaPlayerAdapter.attachAVLayerToView(self.view)
      
      self.setupPeriodicTimeObserver()
      self.attachControlsToParent(to: self)
    }
  }

  
  private func toggleFullScreen() {
    // Lógica para alternar o modo de tela cheia
    print("Alternar tela cheia")
  }
  
  private func setupPeriodicTimeObserver() {
    mediaPlayerAdapter.addPeriodicTimeObserver() { [weak self] seconds in
//      guard let self = self else { return }
      
//      guard let currentItem = self?.player?.currentItem else { return }
      
      //      self.missingDuration = mediaPlayerAdapter.duration - seconds
      //      self.currentTime = time.seconds
      //      mediaSession.updateNowPlayingInfo(time: time.seconds)
      
      let loadedTimeRanges = self?.player?.currentItem?.loadedTimeRanges
      if let firstTimeRange = loadedTimeRanges?.first?.timeRangeValue {
        let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
        let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
        let totalBuffering = (bufferedStart + bufferedDuration) / (self!.mediaPlayerAdapter.duration ?? 1)
        self?.viewModel.updateBufferingProgress(to: totalBuffering)
      }
      
      DispatchQueue.main.async {
        guard let self = self else { return }
        if self.isSeeking == false, seconds <= self.mediaPlayerAdapter.duration ?? 1 {
          let progress = CGFloat(seconds / (self.mediaPlayerAdapter.duration ?? 1))
          self.viewModel.updateSliderProgress(to: progress)
          //          let progressInfo = ["progress": sliderProgress, "buffering": bufferingProgress]
          //          NotificationCenter.default.post(name: .EventVideoProgress, object: nil, userInfo: progressInfo)
        }
      }
    }
  }
}
