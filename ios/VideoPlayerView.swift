//
//  VideoPlayerView.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 22/02/24.
//

import SwiftUI
import AVKit
import Combine

@available(iOS 13.0, *)
struct VideoPlayerView: View {
  var size: CGSize
  var edgeInsets: EdgeInsets
  private var onTapFullScreenControl: (Bool) -> Void
  
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
  
  @State private var playbackDuration: Double = 0
  @State private var uiSafeArea: CGRect!
  @State private var videoPlayerSize: CGSize!
  
  @State private var isFullScreen: Bool = false
  
  init(
    size: CGSize,
    safeArea: EdgeInsets,
    player: AVPlayer,
    thumbnails: [UIImage],
    onTapFullScreenControl: @escaping (Bool) -> Void
  ) {
    self.size = size
    self.edgeInsets = safeArea
    self.player = player
    self.onTapFullScreenControl = onTapFullScreenControl
    _thumbnailsFrames = State(initialValue: thumbnails)
    _uiSafeArea = State(
      initialValue:
        UIScreen.main.bounds.inset(by: UIEdgeInsets(
          top: safeArea.top,
          left: safeArea.leading,
          bottom: safeArea.bottom,
          right: safeArea.trailing
        ))
    )
  }
  
  var body: some View {
    VStack {
      let videoPlayerSize: CGSize = .init(width: size.width, height: size.height)
      
      ZStack {
        CustomVideoPlayer(player: player)
          .edgesIgnoringSafeArea(Edge.Set.all)
          .overlay(
            Rectangle()
              .fill(Color.black.opacity(0.4))
              .opacity(showPlayerControls || isDraggingSlider ? 1 : 0)
              .animation(.easeInOut(duration: 0.35), value: isDraggingSlider)
              .overlay(
                PlaybackControls()
              )
              .edgesIgnoringSafeArea(Edge.Set.all)
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
            VStack {
              HeaderControls()
                .opacity(showPlayerControls && !isDraggingSlider ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showPlayerControls && !isDraggingSlider)
              Spacer()
              VideoSeekerView()
              HStack {
                Spacer()
                SettingsControl()
                FullScreenControl()
              }
              .opacity(showPlayerControls && !isDraggingSlider ? 1 : 0)
              .animation(.easeInOut(duration: 0.2), value: showPlayerControls && !isDraggingSlider)
            }
              .padding(.leading, 12)
              .padding(.trailing, 12)
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
      
      NotificationCenter.default.addObserver(
        playbackObserver,
        selector: #selector(PlayerObserver.generatedThumbnailFrames(_:)),
        name: Notification.Name("frames"),
        object: nil
      )


      isObservedAdded = true
    }
    .onReceive(playbackObserver.$isFinishedPlaying) { finished in
      if finished {
        self.isFinishedPlaying = true
        updateImage()
      }
    }
    .onReceive(playbackObserver.$thumbnailsFrames) { frames in
        DispatchQueue.main.async {
            if !frames.isEmpty {
              self.thumbnailsFrames = frames
            }
        }
    }
    .onReceive(playbackObserver.$playbackDuration) { duration in
      if duration != 0.0 {
        playbackDuration = duration
      }
      guard let currentItem = player.currentItem else { return }
      
      if  currentItem.duration.seconds != 0.0 {
        playbackDuration = currentItem.duration.seconds
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
  }
  


}

// MARK: -- View Builder
@available(iOS 13.0, *)
extension VideoPlayerView {
  
  @ViewBuilder
  func HeaderControls() -> some View {
      HStack {
        Button (action: {
//          onTapExit()
        }) {
          Image(systemName: "arrow.left")
            .font(.system(size: 15))
            .foregroundColor(.white)
        }
        .padding(.leading, 8)
        Spacer()
        Text("videoTitle").font(.system(size: 12)).foregroundColor(.white)
        Spacer()
      }
    }

  @ViewBuilder
  func VideoSeekerThumbnailView() -> some View {
    let thumbSize: CGSize = .init(width: 200, height: 100)
    HStack {
      if let draggingImage {
        VStack {
          Image(uiImage: draggingImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: thumbSize.width, height: thumbSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(.white, lineWidth: 2)
            )
          Group {
            if let currentItem =  player.currentItem {
              Text(stringFromTimeInterval(interval: TimeInterval(truncating: (sliderProgress * currentItem.duration.seconds) as NSNumber)))
                .font(.caption)
                .foregroundColor(.white)
                .fontWeight(.semibold)
            }
          }
        }
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
    .offset(x: sliderProgress * (uiSafeArea.width - thumbSize.width))
    .animation(.easeInOut(duration: 0.2), value: isDraggingSlider)
    
  }
  
  @ViewBuilder
  func VideoSeekerView() -> some View {
    let calculatePercentSizeSeekerView = calculateSizeByWidthWithoutRounded(0.8, 0.1) > 0.9 ? 0.9 : calculateSizeByWidthWithoutRounded(0.8, 0.1)
    let calculateSizeDurationText = calculateSizeByWidth(size8, variantPercent10)
    
    let uiSafeAreaWidth = (uiSafeArea.width * calculatePercentSizeSeekerView)
    VStack(alignment: .leading) {
      VideoSeekerThumbnailView()
        .padding(.bottom, 8)
      HStack {
        ZStack(alignment: .leading) {
          Rectangle()
            .fill(.gray).opacity(0.5)
            .frame(width: uiSafeAreaWidth)
            .cornerRadius(8)
          
          Rectangle()
            .fill(.red)
            .frame(width: uiSafeAreaWidth * sliderProgress)
            .cornerRadius(8)
          
          HStack {}
            .overlay(
              Circle()
                .fill(.red)
                .frame(width: 15, height: 15)
                .frame(width: 50, height: 50)
                .contentShape(Rectangle())
                .offset(x: uiSafeAreaWidth * sliderProgress)
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
                      let calculatedProgress = (translationX / uiSafeAreaWidth) + lastDraggedProgress
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
        .frame(height: 3)
        
        Text(stringFromTimeInterval(interval: playbackDuration))
          .font(.system(size: calculateSizeDurationText))
          .foregroundColor(.white)
      }
      .opacity(showPlayerControls || isSeeking ? 1 : 0)
      .animation(.easeInOut(duration: 0.2), value: showPlayerControls)

    }
    .padding(.bottom, -10)
  }
  
  @ViewBuilder
  func PlaybackControls() -> some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        Button(action: {
          onPlaybackManager(seekToZeroCompletion: { completed in
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
        .frame(minWidth: 25, minHeight: 25)
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
  
  @ViewBuilder
  func FullScreenControl() -> some View {

//    let color = fullScreenConfig?["color"] as? String
//    let isHidden = fullScreenConfig?["hidden"] as? Bool
    
    Button (action: {
      isFullScreen.toggle()
      self.onTapFullScreenControl(true)
    }) {
      Image(
        systemName:
          true ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
      )
      .padding(8)
    }
    .font(.system(size: 15))
//    .foregroundColor(Color(transformStringIntoUIColor(color: color)))
    .foregroundColor(.white)
    .rotationEffect(.init(degrees: 90))
//    .opacity(isHidden ?? false ? 0 : 1)
  }
  
  @ViewBuilder
  func SettingsControl() -> some View {
    Button(action: {
        withAnimation(.linear(duration: 0.2)) {
//            onTapSettings()
        }
    }) {
        Image(systemName: "gear")
            .font(.system(size: 15))
            .foregroundColor(.white)
            .padding(8)
    }
    .fixedSize(horizontal: true, vertical: true)
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
      DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: timeoutTask)
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
  }
  
  private func onPlaybackManager(seekToZeroCompletion: @escaping (Bool) -> Void) {
    if isFinishedPlaying {
      isFinishedPlaying = false
      player.seek(to: .zero, completionHandler: seekToZeroCompletion)
      sliderProgress = .zero
      lastDraggedProgress = .zero
    } else {
      if player.timeControlStatus == .paused  {
        player.play()
        timeoutControls()
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
}

// MARK: -- CustomView
@available(iOS 13.0, *)
struct CustomView : View {
  var player: AVPlayer
  var thumbnails: [UIImage]
  var onTapFullScreenControl: (Bool) -> Void
  
  var body: some View {
    GeometryReader {
      let size = $0.size
      let safeArea = $0.safeAreaInsets
      VideoPlayerView(size: size, safeArea: safeArea, player: player, thumbnails: thumbnails, onTapFullScreenControl: onTapFullScreenControl)
    }
  }
}


import UIKit
import AVFoundation

@available(iOS 13.0, *)
class VideoPlayerViewController: UIViewController {
  private var player: AVPlayer?
  private var thumbnails: [UIImage]
  private var onTapFullScreenControl: (Bool) -> Void
  private var safeAreaInsets: UIEdgeInsets

  init(player: AVPlayer, thumbnails: [UIImage], onTapFullScreenControl: @escaping (Bool) -> Void, safeAreaInsets: UIEdgeInsets) {
        
        self.player = player
    self.thumbnails = thumbnails
    self.onTapFullScreenControl = onTapFullScreenControl
    self.safeAreaInsets = safeAreaInsets
    super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .black
    view.frame = UIScreen.main.bounds.inset(by: safeAreaInsets)
    
    let playerView = UIHostingController(rootView:  VideoPlayerView(size: UIScreen.main.bounds.inset(by: safeAreaInsets).size, safeArea: EdgeInsets(top: safeAreaInsets.top, leading: safeAreaInsets.left, bottom: safeAreaInsets.bottom, trailing: safeAreaInsets.right), player: player!, thumbnails: thumbnails, onTapFullScreenControl: { [self] _ in
      onTapFullScreenControl(false)
    }))
    playerView.view.frame =  UIScreen.main.bounds
    view.addSubview(playerView.view)
  }
  
//  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//      super.viewWillTransition(to: size, with: coordinator)
//
//      // Update the frame size when the device orientation changes
//      coordinator.animate(alongsideTransition: { _ in
//          self.view.frame = CGRect(origin: .zero, size: size)
//          self.view.subviews.forEach { subview in
//              subview.frame = self.view.bounds
//          }
//
//          // Update AVPlayerLayer frame
//          if let playerLayer = self.view.layer.sublayers?.first as? AVPlayerLayer {
//              playerLayer.frame = self.view.bounds
//          }
//      }, completion: nil)
//  }

    deinit {
        // Stop playback and release resources when the view controller is deallocated
    }
}

