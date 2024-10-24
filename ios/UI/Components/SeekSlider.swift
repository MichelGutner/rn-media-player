//
//  SeekSlider.swift
//  Pods
//
//  Created by Michel Gutner on 03/10/24.
//

import AVKit
import SwiftUI

@available(iOS 14.0, *)
struct CustomSeekSlider : View {
  @State var player: AVPlayer? = nil
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
  
  @State private var isLoading = true
  
  var body: some View {
    HStack {
      VStack {
        GeometryReader { geometry in
            Thumbnails(
              duration: $duration,
              geometry: geometry,
              UIControlsProps: $UIControlsProps,
              sliderProgress: $sliderProgress,
              isSeeking: .constant(isDraggedSeekSlider),
              draggingImage: $draggingImage
            )
          ZStack(alignment: .leading) {
            Rectangle()
              .fill(Color(uiColor: (UIControlsProps?.seekSlider.maximumTrackColor ?? .systemFill)))
              .frame(width: geometry.size.width)
              .cornerRadius(16)
            
            Rectangle()
              .fill(Color(uiColor: (UIControlsProps?.seekSlider.seekableTintColor ?? .systemGray3)))
              .frame(width: bufferingProgress * geometry.size.width)
              .cornerRadius(12)
            
            Rectangle()
              .fill(Color(uiColor: (UIControlsProps?.seekSlider.minimumTrackColor ?? .blue)))
              .frame(width: sliderProgress * geometry.size.width)
              .cornerRadius(12)
            
            HStack {}
              .overlay(
                Circle()
                  .fill(Color(uiColor: (UIControlsProps?.seekSlider.thumbImageColor ?? UIColor.white)))
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
                        cancelTimeoutWorkItem()
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
                          canPlaying()
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
        .onAppear {
          if !isStarted {
            isStarted = true
            configurePlayer()
          }
        }
      }
      TimeCodes(time: $duration, UIControlsProps: $UIControlsProps)
    }
    .opacity(!isLoading ? 1 : 0)
    .onAppear {
      NotificationCenter.default.addObserver(forName: .AVPlayerThumbnails, object: nil, queue: .main, using: { notification in
        let thumbnails = notification.object as! [UIImage]
        thumbnailsUIImageFrames = thumbnails
      })
      NotificationCenter.default.addObserver(forName: .DoubleTapNotification, object: nil, queue: .main, using: { notification in
        isSeekingByDoubleTap = notification.object as! Bool
      })
      
      NotificationCenter.default.addObserver(forName: .AVPlayerInitialLoading, object: nil, queue: .main, using: { notification in
        isLoading = notification.object as! Bool
      })
    }
  }
  
  private func configurePlayer() {
    guard let player = player else { return }
    guard let _ = player.currentItem else {return}
    
    player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 2), queue: .main) { [self] time in
      let strongSelf = self
      guard let currentItem = player.currentItem else {
        return
      }
      
      if time.seconds.isNaN || currentItem.duration.seconds.isNaN {
        return
      }
      
      guard let duration = player.currentItem?.duration.seconds else { return }
      self.duration = duration
      
      let loadedTimeRanges = currentItem.loadedTimeRanges
      if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
        let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
        let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
        let totalBuffering = (bufferedStart + bufferedDuration) / duration
        strongSelf.updateBufferProgress(totalBuffering)
      }
      
      DispatchQueue.main.async {
        if !strongSelf.isSeeking, time.seconds <= currentItem.duration.seconds {
          strongSelf.sliderProgress = CGFloat(time.seconds / duration)
          strongSelf.lastDraggedProgresss = strongSelf.sliderProgress
        }
      }
    }
  }
  
  private func updateBufferProgress(_ progress: CGFloat) {
      self.bufferingProgress = progress
  }
}
