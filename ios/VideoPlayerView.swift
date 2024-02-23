//
//  VideoPlayerView.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 22/02/24.
//

import SwiftUI
import AVKit

@available(iOS 13.0, *)
struct VideoPlayerView: View {
  var size: CGSize
  var safeArea: EdgeInsets
  var url: String
  
  @ObservedObject private var playbackObserver = PlayerObserver()
  
  @State private var player: AVPlayer
  @State private var showPlayerControls: Bool = false
  @State private var isPlaying: Bool = true
  @State private var timeoutTask: DispatchWorkItem?
  @State private var playPauseimageName: String = "pause.fill"
  
  @GestureState private var isDraggingSlider: Bool = false
  @State private var sliderProgress = 0.0
  @State private var lastDraggedProgress: CGFloat = 0
  @State private var isSeeking: Bool = false
  @State private var buffering = 0.0
  @State private var isFinishedPlaying: Bool = false
  @State private var isObservedAdded: Bool = false
  
  @State private var thumbnailsFrames: [UIImage] = []
  @State private var draggingImage: UIImage?
  @State private var playerItemStatusObservation: NSKeyValueObservation?
  
  
  init(size: CGSize, safeArea: EdgeInsets, url: String, player: AVPlayer) {
    self.size = size
    self.safeArea = safeArea
    self.url = url
    self.player = player
//    self.player = {
//      if let bundle = Bundle.main.path(forResource: "Test", ofType: "mp4") {
//        print("testing")
//        let url = URL(fileURLWithPath: bundle)
//        return AVPlayer(url: url)
//      } else {
//        print("hoje não", url)
//        return AVPlayer(url: URL(string: url)!)
//      }
//    }()
  }
  
  var body: some View {
    
    VStack {
      let videoPlayerSize: CGSize = .init(width: size.width, height: size.height)
      
      ZStack {
        CustomVideoPlayer(player: player)
          .overlay(
            Rectangle()
              .fill(Color.black.opacity(0.4))
              .opacity(showPlayerControls || isDraggingSlider ? 1 : 0)
              .animation(.easeInOut(duration: 0.35), value: isDraggingSlider)
              .overlay(
                PlaybackControls()
              )
          )
          .overlay(
            DoubleTapManager(
              onTapBackward: { value in
                backwardTime(Double(value))
              },
              onTapForward: { value in
                forwardTime(Double(value))
              },
              isFinished: {
//                isFinished()
              },
              advanceValue: 15,
              suffixAdvanceValue: "seconds"
            )
          )
          .onTapGesture {
            withAnimation(.easeOut(duration: 0.35)) {
              showPlayerControls.toggle()
            }
            
            if isPlaying {
              timeoutControls()
            }
          }
          .overlay(
            VideoSeekerView()
          )
      }
      .frame(width: videoPlayerSize.width, height: videoPlayerSize.height)
    }
    .onAppear {
      guard !isObservedAdded else { return }
      updateImage()
      player.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main) { [self] _ in
        updatePlayerTime()
      }
      
      NotificationCenter.default.addObserver(
        playbackObserver,
        selector: #selector(PlayerObserver.playbackItem(_:)),
        name: .AVPlayerItemNewAccessLogEntry,
        object: player.currentItem
      )
      
      NotificationCenter.default.addObserver(
        playbackObserver,
        selector: #selector(PlayerObserver.itemDidFinishPlaying(_:)),
        name: .AVPlayerItemDidPlayToEndTime,
        object: player.currentItem
      )
      playerItemStatusObservation = player.observe(\.status, options: [.new]) { [self] (item, _) in
        guard item.status == .readyToPlay else {
//          self?.onError?(extractPlayerErrors(item))
          return
        }
        generatingThumbnailsFrames()
      }
      
      isObservedAdded = true
    }
    .onDisappear {
      playerItemStatusObservation?.invalidate()
    }
    .onReceive(playbackObserver.$isFinishedPlaying) { finished in
      if finished {
        self.isFinishedPlaying = true
      }
    }
    
  }
  


}

// MARK: -- View Builder
@available(iOS 13.0, *)
extension VideoPlayerView {
  @ViewBuilder
  func VideoSeekerThumbnailView(_ videoSize: CGSize) -> some View {
    let thumbSize: CGSize = .init(width: 200, height: 100)
    HStack {
      if let draggingImage {
        Image(uiImage: draggingImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: thumbSize.width, height: thumbSize.height)
          .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
              .stroke(.white, lineWidth: 2)
          )
      } else {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
          .fill(.black)
          .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
              .stroke(.white, lineWidth: 2)
          )
      }
    }
    .frame(width: thumbSize.width, height: thumbSize.height)
    .opacity(isDraggingSlider ? 1 : 0)
    .offset(x: sliderProgress * (videoSize.width - thumbSize.width))
    .animation(.easeInOut(duration: 0.2), value: isDraggingSlider)
    
  }
  
  @ViewBuilder
  func VideoSeekerView() -> some View {
    VStack(alignment: .leading) {
      Spacer()
      VideoSeekerThumbnailView(size)
        .padding(.bottom, 12)
      ZStack(alignment: .leading) {
        let safeAreaWidth = UIScreen.main.bounds.inset(by: UIEdgeInsets(top: safeArea.top, left: safeArea.leading, bottom: safeArea.bottom, right: safeArea.trailing)).width
  
        Rectangle()
          .fill(.gray).opacity(0.5)
          .frame(width: safeAreaWidth)
          .cornerRadius(8)
        
        Rectangle()
          .fill(.white).opacity(0.6)
          .frame(width: safeAreaWidth * buffering)
          .cornerRadius(8)
        
        Rectangle()
          .fill(.red)
          .frame(width: safeAreaWidth * sliderProgress)
          .cornerRadius(8)
        
        HStack {}
          .overlay(
            Circle()
              .fill(.red)
              .frame(width: 15, height: 15)
              .frame(width: 50, height: 50)
              .contentShape(Rectangle())
              .offset(x: safeAreaWidth * sliderProgress)
              .gesture(
                DragGesture()
                  .updating($isDraggingSlider, body: { _, out, _ in
                    out = true
                  })
                  .onChanged({ value in
                    if let timeoutTask {
                      timeoutTask.cancel()
                    }
                    
                    let translationX: CGFloat = value.translation.width
                    let calculatedProgress = (translationX / safeAreaWidth) + lastDraggedProgress
                    sliderProgress = max(min(calculatedProgress, 1), 0)
                    isSeeking = true
                    
                    let dragIndex = Int(sliderProgress / 0.01)
                    
                    if thumbnailsFrames.indices.contains(dragIndex) {
                      draggingImage = thumbnailsFrames[dragIndex]
                    }
                  })
                  .onEnded({ value in
                    lastDraggedProgress = sliderProgress
                    if let currentItem = player.currentItem {
                      let duration = currentItem.duration.seconds
                      let targetTime = duration * sliderProgress
                      let targetCMTime = CMTime(seconds: targetTime, preferredTimescale: Int32(NSEC_PER_SEC))
                      
                      if targetTime < 1 {
                        isFinishedPlaying = false
                      }
                      
                      player.seek(to: targetCMTime)
                    }
                    
                    if isPlaying {
                      timeoutControls()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                      isSeeking = false
                    })
                  })
              )
          )
      }
      .opacity(showPlayerControls || isSeeking ? 1 : 0)
      .animation(.easeInOut(duration: 0.2), value: showPlayerControls)
      .frame(height: 3)
    }
    .onReceive(playbackObserver.$playbackDuration) { duration in
      if duration != 0.0 {
//        playbackDuration = duration
      }
      guard let currentItem = player.currentItem else { return }
      if  currentItem.duration.seconds != 0.0 {
//        playbackDuration = currentItem.duration.seconds
        sliderProgress = player.currentTime().seconds / (player.currentItem?.duration.seconds)!
        lastDraggedProgress = sliderProgress
        
        let loadedTimeRanges = currentItem.loadedTimeRanges
        if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
          let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
          let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
          buffering = (bufferedStart + bufferedDuration) / currentItem.duration.seconds
        }
      }
    }
    .padding(.bottom, 16)
  }
  
  @ViewBuilder
  func PlaybackControls() -> some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        Button(action: {
          onPlaybackManager(completionHandler: { completed in
            if completed {
              updateImage()
            }
          })
        }) {
//          if isLoading {
//            LoadingManager(config: [:])
//          } else {
            Image(systemName: playPauseimageName)
              .foregroundColor(.white)
              .font(.system(size: 20 + 5))
//          }
        }
        .padding(size16)
        .background(Color(.black).opacity(0.2))
        .cornerRadius(.infinity)
        Spacer()
      }
      .fixedSize(horizontal: true, vertical: true)
      Spacer()
    }
    .opacity(showPlayerControls && !isDraggingSlider ? 1 : 0)
    .animation(.easeInOut(duration: 0.2), value: showPlayerControls && !isDraggingSlider)
  }
}


// MARK: -- Private Functions
@available(iOS 13.0, *)
extension VideoPlayerView {
  private func timeoutControls() {
    if let timeoutTask {
      timeoutTask.cancel()
    }
    
    timeoutTask = .init(block: {
      withAnimation(.easeInOut(duration: 0.35)) {
        showPlayerControls = false
      }
    })
    
    if let timeoutTask {
      DispatchQueue.main.asyncAfter(deadline: .now() + 3 , execute: timeoutTask)
    }
  }
    
  private func updatePlayerTime() {
    guard let currentItem = player.currentItem else { return }
    
    let currentTime = currentItem.currentTime().seconds
    let duration = currentItem.duration.seconds
    
    let loadedTimeRanges = currentItem.loadedTimeRanges
    if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
      let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
      let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
      buffering = (bufferedStart + bufferedDuration) / duration
      //      onVideoProgress(["progress": currentTime, "bufferedDuration": bufferedStart + bufferedDuration])
    }
    if currentTime < duration {
      //      playbackProgress = currentTime
      //      playbackDuration = duration
      let calculatedProgress = currentTime / duration
      if !isSeeking {
        sliderProgress = calculatedProgress
        lastDraggedProgress = sliderProgress
      }
      if calculatedProgress >= 1 {
        isFinishedPlaying = true
        isPlaying = false
      }
    } else {
      if let duration = player.currentItem?.duration, !duration.seconds.isNaN {
        isFinishedPlaying = true
      }
    }
    
    //    if let duration = avPlayer.currentItem?.duration, !duration.seconds.isNaN {
    //      isLoading = false
    //    }
  }
  
  private func onPlaybackManager(completionHandler: @escaping (Bool) -> Void) {
    if isFinishedPlaying {
      isFinishedPlaying = false
      player.seek(to: .zero)
      sliderProgress = .zero
      lastDraggedProgress = .zero
    } else {
      if player.timeControlStatus == .paused  {
        player.play()
        timeoutControls()
        //        status = .playing
      } else {
        player.pause()
        if let timeoutTask {
          timeoutTask.cancel()
        }
      }
    }
    updateImage()
    
    withAnimation(.easeInOut(duration: 0.2)) {
      isPlaying.toggle()
    }
    //    onTapPlayPause(["status": PlayingStatusManager(status)])
  }
  
  private func updateImage() {
    guard let currentIem = player.currentItem else { return }
    if player.currentTime().seconds >= (currentIem.duration.seconds - 3) {
      isFinishedPlaying = true
      playPauseimageName = "gobackward"
    } else {
      withAnimation(.easeInOut(duration: 0.1)) {
        player.timeControlStatus == .paused ? (playPauseimageName = "play.fill") : (playPauseimageName = "pause.fill")
      }
      isFinishedPlaying = false
    }
  }
  
  private func forwardTime(_ timeToChange: Double) {
    let forward = videoTimerManager(avPlayer: player)
    forward.change(timeToChange)
  }
  
  private func backwardTime(_ timeToChange: Double) {
    let backward = videoTimerManager(avPlayer: player)
    backward.change(-Double(timeToChange))
  }
  
  private func generatingThumbnailsFrames() {
      Task.detached {
        guard let asset = await player.currentItem?.asset else { return }

        do {
          // Load the duration of the asset
          let totalDuration = asset.duration.seconds
          var framesTimes: [NSValue] = []
          
          // Generate thumbnails frames
          let generator = AVAssetImageGenerator(asset: asset)
          generator.appliesPreferredTrackTransform = true
          generator.maximumSize = .init(width: 250, height: 250)
          
          
          for progress in stride(from: 0, to: 4, by: 0.01) {
            let time = CMTime(seconds: totalDuration * Double(progress), preferredTimescale: 600)
            framesTimes.append(time as NSValue)
          }
          
          generator.generateCGImagesAsynchronously(forTimes: framesTimes) { requestedTime, image, _, _, error in
            guard let cgImage = image, error == nil else {
              // Handle the error
              return
            }
            
            DispatchQueue.main.async {
              let uiImage = UIImage(cgImage: cgImage)
              thumbnailsFrames.append(uiImage)
            }
          }
        }
      }
  }


}

// MARK: -- CustomView
@available(iOS 13.0, *)
struct CustomView : View {
  var playerUrl: String
  var player: AVPlayer
  
  var body: some View {
    GeometryReader {
      let size = $0.size
      let safeArea = $0.safeAreaInsets
      VideoPlayerView(size: size, safeArea: safeArea, url: playerUrl, player: player)
    }
  }
}
