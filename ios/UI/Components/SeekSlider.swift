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
  @State var player: AVPlayer? = nil
  var observable: ObservableObjectManager
  @Binding var UIControlsProps: Styles?
  var cancelTimeoutWorkItem: () -> Void
  var scheduleHideControls: () -> Void
  var canPlaying: () -> Void
  
  @State private var interval = CMTime(value: 1, timescale: 2)
  @State private var sliderProgress: CGFloat = 0.0
  @State private var bufferingProgress: CGFloat = 0.0
  @State private var lastDraggedProgresss: CGFloat = 0.0
  @GestureState private var isDraggedSeekSlider: Bool = false
  @State private var isSeeking: Bool = false
  
  @State private var isSeekingByDoubleTap: Bool = false
  
  @State private var tolerance = CMTime(seconds: 0.1, preferredTimescale: Int32(NSEC_PER_SEC))
  
  @State private var seekerThumbImageSize: CGSize = .init(width: 12, height: 12)
  @State private var thumbnailsUIImageFrames: [UIImage] = []
  @State private var draggingImage: UIImage? = nil
  @State private var isStarted: Bool = false
  
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
              Rectangle()
              //                .fill(Color(uiColor: (UIControlsProps?.seekSlider.maximumTrackColor ?? .systemFill)))
                .fill(Color(uiColor: (.systemFill)))
                .frame(width: geometry.size.width)
                .cornerRadius(16)
              
              Rectangle()
              //                .fill(Color(uiColor: (UIControlsProps?.seekSlider.seekableTintColor ?? .systemGray3)))
                .fill(Color(uiColor: (.systemGray3)))
                .frame(width: bufferingProgress * geometry.size.width)
                .cornerRadius(12)
              
              Rectangle()
              //                .fill(Color(uiColor: (UIControlsProps?.seekSlider.minimumTrackColor ?? .blue)))
                .fill(Color(uiColor: (.blue)))
                .frame(width: sliderProgress * geometry.size.width)
                .cornerRadius(12)
              
              HStack {}
                .overlay(
                  Circle()
                  //                    .fill(Color(uiColor: (UIControlsProps?.seekSlider.thumbImageColor ?? UIColor.white)))
                    .fill(Color(uiColor: (UIColor.white)))
                    .frame(width: 12, height: 12)
                    .frame(width: 40, height: 40)
                    .background(Color(uiColor: isDraggedSeekSlider ? .systemFill : .clear))
                    .cornerRadius(.infinity)
                    .opacity(isSeekingByDoubleTap ? 0.001 : 1)
                    .contentShape(Rectangle())
                    .offset(x: sliderProgress * geometry.size.width)
                    .gesture(
                      DragGesture()
                        .updating($isDraggedSeekSlider, body: {_, out, _ in
                          out = true
                        })
                        .onChanged({ value in
                          NotificationCenter.default.post(name: .SeekingNotification, object: true)
                          //                          cancelTimeoutWorkItem()
                          let translation = value.translation.width / geometry.size.width
                          sliderProgress = max(min(translation + lastDraggedProgresss, 1), 0)
                          isSeeking = true
                          
                          let dragIndex = Int(sliderProgress / 0.01)
                          if thumbnailsUIImageFrames.indices.contains(dragIndex) {
                            draggingImage = thumbnailsUIImageFrames[dragIndex]
                          }
                        })
                        .onEnded({ value in
                          scheduleHideControls()
                          lastDraggedProgresss = sliderProgress
                          guard let playerItem = player?.currentItem else { return }
                          
                          let targetTime =  playerItem.duration.seconds * sliderProgress
                          
                          let targetCMTime = CMTime(seconds: targetTime, preferredTimescale: Int32(NSEC_PER_SEC))
                          
                          if sliderProgress < 1 {
                            //                            canPlaying()
                          }
                          
                          NotificationCenter.default.post(name: .SeekingNotification, object: false)
                          player?.seek(to: targetCMTime, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: { completed in
                            if (completed) {
                              isSeeking = false
                            }
                          })
                        })
                    )
                )
            }
          }
          .frame(height: 6)
        }
        HStack {
          TimeCodes(time: $currentTime, UIControlsProps: .constant(.none))
          Spacer()
          TimeCodes(time: $missingDuration, UIControlsProps: .constant(.none))
        }
      }
    }
    .onReceive(observable.$thumbnailsDictionary, perform: { thumbnails in
      guard let thumbnails,
              let enabled = thumbnails["enabled"] as? Bool,
              enabled,
              let url = thumbnails["url"] as? String
      else { return }
      print("testings", url)
      generatingThumbnailsFrames(url)
    })
    .onAppear {
      setupPeriodicTimeObserver()
    }
    .onDisappear {
      thumbnailsUIImageFrames.removeAll()
      draggingImage = nil
      if let timeObserver {
        player?.removeTimeObserver(timeObserver)
      }
    }
  }
  
  private func setupPeriodicTimeObserver() {
    guard let player = player else { return }
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
      
      let loadedTimeRanges = currentItem.loadedTimeRanges
      if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
        let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
        let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
        let totalBuffering = (bufferedStart + bufferedDuration) / duration
        self.updateBufferProgress(totalBuffering)
      }
      
      DispatchQueue.main.async {
        if !self.isSeeking, time.seconds <= currentItem.duration.seconds {
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
        
        //  TODO:
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
