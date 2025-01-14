//
//  SeekSlider.swift
//  Pods
//
//  Created by Michel Gutner on 03/10/24.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

public var timeObserver: Any? = nil

@available(iOS 14.0, *)
struct InteractiveMediaSeekSlider : View {
  @ObservedObject private var playbackState = PlaybackStateObservable.shared
  var player: AVPlayer? = nil
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
  var onSeekBegan: (() -> Void)?
  var onSeekEnded: ((_ start: Double, _ end: Double) -> Void)?
  
  var body: some View {
    ZStack {
      VStack {
        MediaSeekSliderRepresentable(
          bufferingProgress: $bufferingProgress,
          sliderProgress: $sliderProgress,
          onProgressBegan: { _ in
            guard let currentItem = player?.currentItem else {
              return
            }
            lastProgress = currentItem.currentTime().seconds / duration
            isSeeking = true
            showThumbnails = true
            onSeekBegan?()
          },
          onProgressChanged: { progress in
            guard let currentItem = player?.currentItem else {
              return
            }
            
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
            
            let targetTime = CMTime(seconds: progressInSeconds, preferredTimescale: 600)
            
//            NotificationCenter.default.post(name: .EventSeekBar, object: nil, userInfo: ["start": (lastProgress, lastProgressInSeconds), "ended": (progress, progressInSeconds)])
            

            onSeekEnded?(lastProgress, progress)
            
            player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { completed in
              if completed {
                isSeeking = false    
              }
            }
          }
        )
        .frame(height: 30)
        
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
    }
  }
  
  private func setupPeriodTimeObserve() {
    guard let player else {
      appConfig.log("not player")
      return
    }
    player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 2), queue: .main) { time in
      guard let currentItem = player.currentItem else {
        return
      }
      
      if time.seconds.isNaN || currentItem.duration.seconds.isNaN {
        return
      }
      
      guard let duration = player.currentItem?.duration.seconds else { return }
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
      
      if !isSeeking {
        sliderProgress = currentTime / duration
      }
    }
  }
  
  private func generatingThumbnailsFrames(_ url: String) {
    if playbackState.isReady {
      return
    }
    
    TaskDetached?.cancel()
    let asset = AVAsset(url: URL(string: url)!)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = .init(width: 230, height: 140)
    
    
    TaskDetached = Task.detached(priority: .userInitiated) {
      do {
        let totalDuration = asset.duration.seconds
        var framesTimes: [NSValue] = []
      
        //  TODO: must be implemented frame times per seconds from bridge
        for progress in stride(from: 0, to: totalDuration / Double(1 * 100), by: 0.01) {
          let time = CMTime(seconds: totalDuration * Double(progress), preferredTimescale: 600)
          framesTimes.append(time as NSValue)
        }
        let localFrames = framesTimes
        
        await withCheckedContinuation { continuation in
          generator.generateCGImagesAsynchronously(forTimes: localFrames) { requestedTime, image, _, _, error in
            guard !TaskDetached!.isCancelled else {
              generator.cancelAllCGImageGeneration()
              continuation.resume()
              return
            }
            guard let cgImage = image, error == nil else {
              return
            }
            
            DispatchQueue.main.async {
              let uiImage = UIImage(cgImage: cgImage)
              thumbnailsUIImageFrames.append(uiImage)
            }
            
            if requestedTime == localFrames.last?.timeValue {
                 continuation.resume()
             }
          }
        }
      }
    }
  }
}
