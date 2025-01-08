//
//  SeekSlider.swift
//  Pods
//
//  Created by Michel Gutner on 03/10/24.
//

import AVKit
import SwiftUI
import Combine

public var timeObserver: Any? = nil

@available(iOS 14.0, *)
struct InteractiveMediaSeekSlider : View {
  var player: AVPlayer?
  @State private var interval = CMTime(value: 1, timescale: 2)
  @State private var sliderProgress: Double = 0.0
  @State private var bufferingProgress: Double = 0.0
  @GestureState private var isDraggedSeekSlider: Bool = false
  @State private var isSeekingWithTap: Bool = false
  
  @State private var tolerance = CMTime(seconds: 0.1, preferredTimescale: Int32(NSEC_PER_SEC))
  
  @State private var seekerThumbImageSize: CGSize = .init(width: 12, height: 12)
  @State private var thumbnailsUIImageFrames: [UIImage] = []
  @State private var draggingImage: UIImage? = nil
  
  @State private var duration: Double = 0.0
  @State private var missingDuration: Double = 0.0
  @State private var currentTime: Double = 0.0
  @State private var showThumbnails: Bool = false

  @State private var lastProgress: Double = 0.0
  @Binding var isSeeking: Bool
  @State private var TaskDetached: Task<Void, Never>?
  
  var body: some View {
    ZStack {
      VStack {
        MediaSeekSliderView(
          bufferingProgress: $bufferingProgress,
          sliderProgress: $sliderProgress,
          onProgressBegan: { _ in
            guard let currentItem = player?.currentItem else {
              return
            }
            
            lastProgress = currentItem.currentTime().seconds / duration
            
            isSeeking = true
            showThumbnails = true
//            mediaSession.cancelTimeoutWorkItem()
          },
          
          onProgressChanged: { progress in
            guard let currentItem = player?.currentItem else {
              return
            }
            
            // Obtém a duração do item atual
            let durationInSeconds = currentItem.duration.seconds
            guard durationInSeconds.isFinite else {
              return
            }
            
            let draggIndex = Int(sliderProgress / 0.01)
            
            if thumbnailsUIImageFrames.indices.contains(draggIndex) {
              draggingImage = thumbnailsUIImageFrames[draggIndex]
            }
          },
          onProgressEnded: { progress in
            showThumbnails = false
            guard let currentItem = player?.currentItem else {
              return
            }
            
            let durationInSeconds = currentItem.duration.seconds
            guard durationInSeconds.isFinite else {
              return
            }
            
            let progressInSeconds = durationInSeconds * progress
            let lastProgressInSeconds = durationInSeconds * lastProgress
            
            let targetTime = CMTime(seconds: progressInSeconds, preferredTimescale: 600)
            
            NotificationCenter.default.post(name: .EventSeekBar, object: nil, userInfo: ["start": (lastProgress, lastProgressInSeconds), "ended": (progress, progressInSeconds)])
            
            if progress < 1 {
//              mediaSession.isFinished = false
            }
            
            player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { completed in
              if completed {
                isSeeking = false
//                mediaSession.scheduleHideControls()
              }
            }
          }
        )
        .frame(height: 24)
        .scaleEffect(x: isSeeking ? 1.03 : 1, y: isSeeking ? 1.5 : 1, anchor: .bottom)
        .animation(.interpolatingSpring(stiffness: 100, damping: 30, initialVelocity: 0.2), value: isSeeking)
        
        HStack {
          TimeCodes(time: $currentTime, UIControlsProps: .constant(.none))
          Spacer()
          TimeCodes(time: $missingDuration, UIControlsProps: .constant(.none), suffixValue: "-")
        }
      }
      .overlay(
        HStack {
          GeometryReader { geometry in
            Thumbnails(
              duration: $duration,
              geometry: geometry,
              UIControlsProps: .constant(.none),
              sliderProgress: $sliderProgress,
              isSeeking: $showThumbnails,
              draggingImage: $draggingImage
            )
            Spacer()
          }
        }
      )
    }
    .background(Color.clear)
    .frame(maxWidth: .infinity)
    .onAppear {
      let thumbnails = appConfig.thumbnails
      if thumbnails != nil {
        guard let thumbnails,
              let enabled = thumbnails["isEnabled"] as? Bool,
              enabled,
              let url = thumbnails["sourceUrl"] as? String
        else { return }
        generatingThumbnailsFrames(url)
      }
      setupPeriodTimeObserve()
    }
    .onDisappear {
      thumbnailsUIImageFrames.removeAll()
      draggingImage = nil
      TaskDetached?.cancel()
      appConfig.log("isDissapearing")
    }
  }
  
  private func setupPeriodTimeObserve() {
    player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 2), queue: .main) { time in
      guard let currentItem = player?.currentItem else {
        return
      }
      
      if time.seconds.isNaN || currentItem.duration.seconds.isNaN {
        return
      }
      
      guard let duration = player?.currentItem?.duration.seconds else { return }
      self.duration = duration
      self.missingDuration = duration - time.seconds
      self.currentTime = time.seconds
      //          mediaSession.updateNowPlayingInfo(time: time.seconds)
      
      let loadedTimeRanges = currentItem.loadedTimeRanges
      if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
        let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
        let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
        let totalBuffering = (bufferedStart + bufferedDuration) / duration
        self.bufferingProgress = totalBuffering
      }
      let playbackState = Shared.instance.source?.playbackState
      
      if !isSeeking, playbackState == .playing {
        sliderProgress = currentTime / duration
      }
    }
  }
  
  private func generatingThumbnailsFrames(_ url: String) {
    if Shared.instance.source?.playbackState != .waiting {
      return
    }
    
    TaskDetached?.cancel()
    
    
    TaskDetached = Task.detached(priority: .userInitiated) {
      let asset = AVAsset(url: URL(string: url)!)
      
      do {
        let totalDuration = asset.duration.seconds
        var framesTimes: [NSValue] = []
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = .init(width: 230, height: 140)
        
        //  TODO: must be implemented frame times per seconds from bridge
        for progress in stride(from: 0, to: totalDuration / Double(1 * 100), by: 0.01) {
          let time = CMTime(seconds: totalDuration * Double(progress), preferredTimescale: 600)
          framesTimes.append(time as NSValue)
        }
        let localFrames = framesTimes
        
        generator.generateCGImagesAsynchronously(forTimes: localFrames) { requestedTime, image, _, _, error in
          guard !TaskDetached!.isCancelled else {
            generator.cancelAllCGImageGeneration()
            return
          }
          guard let cgImage = image, error == nil else {
            return
          }
          
          DispatchQueue.main.async {
            let uiImage = UIImage(cgImage: cgImage)
            thumbnailsUIImageFrames.append(uiImage)
          }
        }
      }
    }
  }
}
