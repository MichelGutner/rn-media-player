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
  @State var options: NSDictionary? = [:]
  @Binding var UIControlsProps: HashableControllers?
  
  @State private var controlsVisible: Bool = true
  @Binding var timeoutWorkItem: DispatchWorkItem?
  var scheduleHideControls: () -> Void
  @State private var interval = CMTime(value: 1, timescale: 2)
  
  @Binding var sliderProgress: CGFloat
  @State private var bufferingProgress: CGFloat = 0.0
  @Binding var lastDraggedProgresss: CGFloat
  @GestureState var isDraggedSeekSlider: Bool
  @Binding var isSeeking: Bool
  @Binding var isSeekingByDoubleTap: Bool
  
  @State private var tolerance = CMTime(seconds: 0.1, preferredTimescale: Int32(NSEC_PER_SEC))
  
  @Binding var seekerThumbImageSize: CGSize
  @Binding var thumbnailsFrames: [UIImage]
  @Binding var draggingImage: UIImage?
  
  var body: some View {
    VStack {
      ZStack(alignment: .leading) {
        GeometryReader { geometry in
          Rectangle()
            .fill(Color(uiColor: (UIControlsProps?.seekSlider.maximumTrackColor ?? .systemFill)))
            .frame(width: geometry.size.width)
            .cornerRadius(16)
            .border(Color(uiColor: (UIControlsProps?.seekSlider.maximumTrackColor ?? .systemFill)), width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
          
          Rectangle()
            .fill(Color(uiColor: (UIControlsProps?.seekSlider.seekableTintColor ?? .systemGray2)))
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
                .background(Color(uiColor: isSeeking ? .systemFill : .clear))
                .cornerRadius(.infinity)
                .opacity(isSeekingByDoubleTap ? 0.001 : 1)
                .contentShape(Rectangle())
                .offset(x: sliderProgress * (geometry.size.width - seekerThumbImageSize.width),  y: geometry.size.height / 2)
                .gesture(
                  DragGesture()
                    .updating($isDraggedSeekSlider, body: {_, out, _ in
                      out = true
                    })
                    .onChanged({ value in
                      let translation = value.translation.width / geometry.size.width
                      sliderProgress = max(min(translation + lastDraggedProgresss, 1), 0)
                      isSeeking = true
                      
                      let dragIndex = Int(sliderProgress / 0.01)
                      if thumbnailsFrames.indices.contains(dragIndex) {
                        draggingImage = thumbnailsFrames[dragIndex]
                      }
                    })
                    .onEnded({ value in
                      lastDraggedProgresss = sliderProgress
                      guard let playerItem = player?.currentItem else { return }
                      
                      let targetTime =  playerItem.duration.seconds * sliderProgress
                      
                      let targetCMTime = CMTime(seconds: targetTime, preferredTimescale: Int32(NSEC_PER_SEC))
                      
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
      .opacity(isSeeking || controlsVisible || isSeekingByDoubleTap ? 1 : 0)
      .onAppear {
        configurePlayer()
      }
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
        
        
        let loadedTimeRanges = currentItem.loadedTimeRanges
        if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
            let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
            let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
            let totalBuffering = (bufferedStart + bufferedDuration) / duration
            strongSelf.updateBufferProgress(totalBuffering)
        }
        
        if !strongSelf.isSeeking, time.seconds <= currentItem.duration.seconds {
          strongSelf.sliderProgress = CGFloat(time.seconds / duration)
          strongSelf.lastDraggedProgresss = strongSelf.sliderProgress
        }
      }
  }
  
  // Atualiza o progresso de buffering
  private func updateBufferProgress(_ progress: CGFloat) {
      self.bufferingProgress = progress
  }
}
