//
//  SeekSlider.swift
//  Pods
//
//  Created by Michel Gutner on 03/10/24.
//

import AVKit
import SwiftUI
import Combine

@available(iOS 14.0, *)
struct InteractiveMediaSeekSlider : View {
  var mediaSession: MediaSessionManager
  @Binding var UIControlsProps: Styles?
  
  @State private var interval = CMTime(value: 1, timescale: 2)
  @State private var sliderProgress: CGFloat = 0.0
  @State private var bufferingProgress: CGFloat = 0.0
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
  
  @State private var timeObservers: [String: Any] = [:]
  @State private var lastProgress: Double = 0.0
  
  var body: some View {
    ZStack {
      
      VStack {
        MediaSeekSliderView(
          mediaSession: .constant(mediaSession),
          sliderProgress: $sliderProgress,
          bufferingProgress: $bufferingProgress,
          
          onProgressBegan: { _ in
            guard let player = mediaSession.player,
                  let currentItem = player.currentItem else {
              return
            }
            
            lastProgress = currentItem.currentTime().seconds / duration
            
            mediaSession.isSeeking = true
            showThumbnails = true
            mediaSession.cancelTimeoutWorkItem()
          },
          
          onProgressChanged: { progress in
            guard let player = mediaSession.player,
                  let currentItem = player.currentItem else {
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
            guard let player = mediaSession.player,
                  let currentItem = player.currentItem else {
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
              mediaSession.isFinished = false
            }
            
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { completed in
              if completed {
                mediaSession.isSeeking = false
                mediaSession.scheduleHideControls()
              }
            }
          }
        )
        .frame(height: 24)
        .scaleEffect(x: mediaSession.isSeeking ? 1.03 : 1, y: mediaSession.isSeeking ? 1.5 : 1, anchor: .bottom)
        .animation(.interpolatingSpring(stiffness: 100, damping: 30, initialVelocity: 0.2), value: mediaSession.isSeeking)
        
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
    .onReceive(mediaSession.$thumbnailsDictionary, perform: { thumbnails in
      guard let thumbnails,
            let enabled = thumbnails["isEnabled"] as? Bool,
            enabled,
            let url = thumbnails["sourceUrl"] as? String
      else { return }
      generatingThumbnailsFrames(url)
    })
    .onAppear {
      setupPeriodicTimeObserver(id: "periodTimeObserveId")
    }
    .onDisappear {
      thumbnailsUIImageFrames.removeAll()
      draggingImage = nil
    }
  }

  private func setupPeriodicTimeObserver(id: String) {
      guard let player = mediaSession.player else { return }
      guard let _ = player.currentItem else { return }

      // Verifica se já existe um observer com o ID fornecido
      if timeObservers[id] != nil {
          return
      }

      let observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 2), queue: .main) { [self] time in
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
          mediaSession.updateNowPlayingInfo(time: time.seconds)

          let loadedTimeRanges = currentItem.loadedTimeRanges
          if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
              let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
              let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
              let totalBuffering = (bufferedStart + bufferedDuration) / duration
              self.updateBufferProgress(totalBuffering)
          }

          DispatchQueue.main.async {
              if !mediaSession.isSeeking, time.seconds <= currentItem.duration.seconds {
                  self.sliderProgress = CGFloat(time.seconds / duration)
                let progressInfo = ["progress": sliderProgress, "buffering": bufferingProgress]
                NotificationCenter.default.post(name: .EventVideoProgress, object: nil, userInfo: progressInfo)
              }
          }
      }

      // Salva o observador no dicionário
      timeObservers[id] = observer
  }
  
  private func updateBufferProgress(_ progress: CGFloat) {
    self.bufferingProgress = progress
  }
  
  private func generatingThumbnailsFrames(_ url: String) {
    Task.detached {
      let asset = AVAsset(url: URL(string: url)!)
      
      do {
        let totalDuration = asset.duration.seconds
        var framesTimes: [NSValue] = []
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = .init(width: 250, height: 150)
        
        //  TODO: must be implemented frame times per seconds from bridge
        for progress in stride(from: 0, to: totalDuration / Double(1 * 100), by: 0.01) {
          let time = CMTime(seconds: totalDuration * Double(progress), preferredTimescale: 600)
          framesTimes.append(time as NSValue)
        }
        let localFrames = framesTimes
        
        generator.generateCGImagesAsynchronously(forTimes: localFrames) { requestedTime, image, _, _, error in
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
