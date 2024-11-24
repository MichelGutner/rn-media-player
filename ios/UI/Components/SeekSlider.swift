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
struct CustomSeekSlider : View {
  var mediaSession: MediaSessionManager
  @Binding var UIControlsProps: Styles?
  
  @State private var interval = CMTime(value: 1, timescale: 2)
  @State private var sliderProgress: CGFloat = 0.0
  @State private var bufferingProgress: CGFloat = 0.0
  @State private var lastDraggedProgresss: CGFloat = 0.0
  @GestureState private var isDraggedSeekSlider: Bool = false
  @State private var isSeekingWithTap: Bool = false
  
  @State private var tolerance = CMTime(seconds: 0.1, preferredTimescale: Int32(NSEC_PER_SEC))
  
  @State private var seekerThumbImageSize: CGSize = .init(width: 12, height: 12)
  @State private var thumbnailsUIImageFrames: [UIImage] = []
  @State private var draggingImage: UIImage? = nil
  
  @State private var duration: Double = 0.0
  @State private var missingDuration: Double = 0.0
  @State private var currentTime: Double = 0.0
  
  @State private var timeObserver: Any? = nil
  
  var body: some View {
    HStack {
      VStack {
        VStack {
          GeometryReader { geometry in
            Thumbnails(
              duration: $duration,
              geometry: geometry,
              UIControlsProps: .constant(.none),
              sliderProgress: $sliderProgress,
              isSeeking: .constant(isDraggedSeekSlider),
              draggingImage: $draggingImage
            )
            ZStack(alignment: .leading) {
              if #available(iOS 16.0, *) {
                ZStack(alignment: .leading) {
                  Rectangle()
                  //                .fill(Color(uiColor: (UIControlsProps?.seekSlider.maximumTrackColor ?? .systemFill)))
                    .fill(Color(uiColor: (.systemFill)))
                    .frame(width: geometry.size.width)
                  
                  Rectangle()
                  //                .fill(Color(uiColor: (UIControlsProps?.seekSlider.seekableTintColor ?? .systemGray3)))
                    .fill(Color(uiColor: (.secondarySystemFill)))
                    .frame(width: bufferingProgress * geometry.size.width)
                  
                  Rectangle()
                  //                .fill(Color(uiColor: (UIControlsProps?.seekSlider.minimumTrackColor ?? .blue)))
                    .fill(Color(uiColor: (.white)))
                    .frame(width: sliderProgress * geometry.size.width)
                }
                .onTapGesture(coordinateSpace: .local) { value in
                  guard let player = mediaSession.player else { return }
                  isSeekingWithTap = true
                  let translation = value.x / geometry.size.width
                  sliderProgress = max(min(translation, 1), 0)
                  
                  lastDraggedProgresss = sliderProgress
                  guard let playerItem = player.currentItem else { return }
                  
                  let targetTime =  playerItem.duration.seconds * sliderProgress
                  let targetCMTime = CMTime(seconds: targetTime, preferredTimescale: Int32(NSEC_PER_SEC))
                  player.seek(to: targetCMTime, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: { completed in
                    if (completed) {
                      DispatchQueue.main.async {
                          self.isSeekingWithTap = false
                      }
                    }
                  })
                }
                .cornerRadius(12)
                .scaleEffect(x: mediaSession.isSeeking ? 1.02 : 1, y: mediaSession.isSeeking ? 1.5 : 1, anchor: .bottom)
                .animation(.interpolatingSpring(stiffness: 100, damping: 30, initialVelocity: 0.2), value: mediaSession.isSeeking)
              } else {
                ZStack(alignment: .leading) {
                  Rectangle()
                  //                .fill(Color(uiColor: (UIControlsProps?.seekSlider.maximumTrackColor ?? .systemFill)))
                    .fill(Color(uiColor: (.systemFill)))
                    .frame(width: geometry.size.width)
                  
                  Rectangle()
                  //                .fill(Color(uiColor: (UIControlsProps?.seekSlider.seekableTintColor ?? .systemGray3)))
                    .fill(Color(uiColor: (.systemGray3)))
                    .frame(width: bufferingProgress * geometry.size.width)
                  
                  Rectangle()
                  //                .fill(Color(uiColor: (UIControlsProps?.seekSlider.minimumTrackColor ?? .blue)))
                    .fill(Color(uiColor: (.blue)))
                    .frame(width: sliderProgress * geometry.size.width)
                }
                .cornerRadius(12)
                .scaleEffect(x: mediaSession.isSeeking ? 1.02 : 1, y: mediaSession.isSeeking ? 1.5 : 1, anchor: .bottom)
                .animation(.interpolatingSpring(stiffness: 100, damping: 30, initialVelocity: 0.2), value: mediaSession.isSeeking)
              }
              
              HStack {}
                .overlay(
                  Circle()
                  //                    .fill(Color(uiColor: (UIControlsProps?.seekSlider.thumbImageColor ?? UIColor.white)))
                    .fill(Color(uiColor: (UIColor.white)))
                    .frame(width: 12, height: 12)
                    .frame(width: 40, height: 40)
                    .background(Color(uiColor: isDraggedSeekSlider ? .systemFill : .clear))
                    .scaleEffect(x: mediaSession.isSeeking ? 1.5 : 1, y: mediaSession.isSeeking ? 1.5 : 1, anchor: .zero)
                    .animation(.interpolatingSpring(stiffness: 100, damping: 30, initialVelocity: 0.2), value: mediaSession.isSeeking)
                    .cornerRadius(.infinity)
                    .opacity(0.0001)
                    .contentShape(Rectangle())
                    .offset(x: sliderProgress * geometry.size.width)
                    .gesture(
                      DragGesture()
                        .updating($isDraggedSeekSlider, body: {_, out, _ in
                          out = true
                        })
                        .onChanged({ value in
                          mediaSession.cancelTimeoutWorkItem()
                          let translation = value.translation.width / geometry.size.width
                          DispatchQueue.main.async {
                            mediaSession.isSeeking = true
                            sliderProgress = max(min(translation + lastDraggedProgresss, 1), 0)
                            
                            let dragIndex = Int(sliderProgress / 0.01)
                            if thumbnailsUIImageFrames.indices.contains(dragIndex) {
                              draggingImage = thumbnailsUIImageFrames[dragIndex]
                            }
                          }
                        })
                        .onEnded({ value in
                          guard let player = mediaSession.player else { return }
                          mediaSession.scheduleHideControls()
                          lastDraggedProgresss = sliderProgress
                          guard let playerItem = player.currentItem else { return }
                          
                          let targetTime =  playerItem.duration.seconds * sliderProgress
                          
                          let targetCMTime = CMTime(seconds: targetTime, preferredTimescale: Int32(NSEC_PER_SEC))
                          
                          if sliderProgress < 1 {
                            mediaSession.isFinished = false
                            mediaSession.scheduleHideControls()
                          }
                          
                          player.seek(to: targetCMTime, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: { completed in
                            if (completed) {
                              DispatchQueue.main.async {
                                mediaSession.isSeeking = false
                              }
                            }
                          })
                        })
                    )
                )
            }
          }
          .frame(height: 8)
          .background(Color.clear)
          .frame(maxWidth: .infinity)
        }
        HStack {
          TimeCodes(time: $currentTime, UIControlsProps: .constant(.none))
          Spacer()
          TimeCodes(time: $missingDuration, UIControlsProps: .constant(.none), suffixValue: "-")
        }
      }
    }
    .onReceive(mediaSession.$thumbnailsDictionary, perform: { thumbnails in
      guard let thumbnails,
              let enabled = thumbnails["enabled"] as? Bool,
              enabled,
              let url = thumbnails["url"] as? String
      else { return }
      generatingThumbnailsFrames(url)
    })
    .onAppear {
      setupPeriodicTimeObserver()
    }
    .onDisappear {
      thumbnailsUIImageFrames.removeAll()
      draggingImage = nil
      if let timeObserver {
        guard let player = mediaSession.player else { return }
        player.removeTimeObserver(timeObserver)
      }
    }
  }
  
  private func setupPeriodicTimeObserver() {
    guard let player = mediaSession.player else { return }
    guard let _ = player.currentItem else {return}
    
    timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 2), queue: .main) { [self] time in
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
          self.lastDraggedProgresss = self.sliderProgress
        }
      }
    }
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
        
        // Generate thumbnails frames
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
