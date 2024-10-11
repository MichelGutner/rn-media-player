//
//  VideoPlayerView.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 22/02/24.
//

let defaultOptions: NSDictionary = [
    "Speeds": [
        "data": [
            ["name": "x0.5", "value": "0.5"],
            ["name": "Normal", "value": "1"],
            ["name": "x1.5", "value": "1.5"],
            ["name": "x2.0", "value": "2.0"],
        ],
        "initialItemSelected": "Normal"
    ]
]


import SwiftUI
import AVKit
import Combine

@available(iOS 14.0, *)
struct VideoPlayerView: View {
    @Namespace private var animationNamespace
    
    @ObservedObject private var playbackObserver = PlaybackObserver()
    var player: AVPlayer
    @Binding var autoPlay: Bool
    @State var options: NSDictionary? = [:]
    var controls: PlayerControls
    var thumbNailsProps: NSDictionary? = [:]
    var enterInFullScreenWhenDeviceRotated = false
    var videoGravity: AVLayerVideoGravity
    @Binding var UIControlsProps: HashableControllers?
    var tapToSeek: NSDictionary? = [:]
    
    @State private var rate: Float = 0.0
    @State private var isFullScreen: Bool = false
    @State private var controlsVisible: Bool = true
    @State private var isReadyToPlay = false
    @State private var isFinishedPlaying: Bool = false
    
    @State private var timeoutWorkItem: DispatchWorkItem?
    @State private var periodicTimeObserver: Any? = nil
    @State private var interval = CMTime(value: 1, timescale: 2)
    
    @State private var tolerance = CMTime(seconds: 0.1, preferredTimescale: Int32(NSEC_PER_SEC))
  
  @State private var initialSelectedOption: String = ""
  
  @State private var observable = PlaybackObservable()
  
  @State private var sliderProgress: CGFloat = 0.0
  @State private var bufferingProgress: CGFloat = 0.0
  @State private var lastDraggedProgresss: CGFloat = 0.0
  
  @GestureState private var isDraggedSeekSlider: Bool = false
  @State private var isSeeking: Bool = false
  @State private var isSeekingByDoubleTap: Bool = false
  
  @State private var seekerThumbImageSize: CGSize = .init(width: 12, height: 12)
  @State private var thumbnailsFrames: [UIImage] = []
  @State private var draggingImage: UIImage?
    
    
  var body: some View {
    GeometryReader { geometry in
      if player.status != .readyToPlay, let _ = player.currentItem {
        VStack {
            Spacer()
            CustomLoading(color: UIControlsProps?.loading.color)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ZStack {
          CustomVideoPlayer(player: player, videoGravity: videoGravity, autoPlay: autoPlay)
            .ignoresSafeArea(edges: isFullScreen ? Edge.Set.all : [])
            .overlay(
              Rectangle()
                .fill(Color.black.opacity(0.4))
                .opacity(!isSeekingByDoubleTap && controlsVisible || isSeeking  ? 1 : 0)
                .animation(.easeInOut(duration: 0.35), value: isSeeking || controlsVisible || isSeekingByDoubleTap)
                .edgesIgnoringSafeArea(Edge.Set.all)
            )
            .overlay(
                DoubleTapManager(
                  onTapBackward: { value in
                    backwardTime(Double(value))
                    isSeekingByDoubleTap = true
                  },
                  onTapForward: { value in
                    forwardTime(Double(value))
                    isSeekingByDoubleTap = true
                  },
                  isFinished: {
                    isSeekingByDoubleTap = false
                  },
                  advanceValue: tapToSeek?["value"] as? Int ?? 15,
                  suffixAdvanceValue: tapToSeek?["suffixLabel"] as? String ?? "seconds"
                )
            )
            .onAppear {
              NotificationCenter.default.addObserver(
                playbackObserver,
                selector: #selector(PlaybackObserver.itemDidFinishPlaying(_:)),
                name: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem
              )
              NotificationCenter.default.addObserver(
                playbackObserver,
                selector: #selector(PlaybackObserver.deviceOrientation(_:)),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
              )
              NotificationCenter.default.addObserver(
                playbackObserver,
                selector: #selector(PlaybackObserver.handleRateChangeNotification(_:)),
                name: .AVPlayerRateDidChange,
                object: nil
              )
            }
            .onReceive(playbackObserver.$isFinished, perform: { isFinished in
              isFinishedPlaying = isFinished
              timeoutWorkItem?.cancel()
            })
            .onReceive(playbackObserver.$changedRate) { changedRate in
              rate = changedRate
              if (player.timeControlStatus == .playing) {
                player.rate = changedRate
              }
            }
            .onTapGesture {
              withAnimation {
                toggleControls()
              }
            }
            .overlay(
              ViewControllers(geometry: geometry)
            )
            .overlay (
              PlaybackControls()
            )
        }
      }
    }
    .preferredColorScheme(.dark)
    .onAppear {
      if player.timeControlStatus == .playing {
        scheduleHideControls()
      }
      
      if let thumbNailsEnabled = thumbNailsProps?["enabled"] as? Bool {
        if let thumbnailsUrl = thumbNailsProps?["url"] as? String, thumbNailsEnabled {
          generatingThumbnailsFrames(thumbnailsUrl)
        }
      }
    }
  }
    
    @ViewBuilder
  func ViewControllers(geometry: GeometryProxy) -> some View {
    VStack {
      Spacer()
      VStack {
        Spacer()
        HStack(alignment: .bottom) {
          Thumbnails(
            player: .constant(player),
            geometry: geometry,
            UIControlsProps: $UIControlsProps,
            thumbnails: .constant(thumbNailsProps),
            sliderProgress: $sliderProgress,
            isSeeking: $isSeeking,
            draggingImage: $draggingImage
          )
          .padding(.bottom, 12)
          Spacer()
        }
        HStack {
          CustomSeekSlider(
            player: player,
            UIControlsProps: $UIControlsProps,
            timeoutWorkItem: $timeoutWorkItem,
            scheduleHideControls: scheduleHideControls,
            sliderProgress: $sliderProgress,
            lastDraggedProgresss: $lastDraggedProgresss,
            isDraggedSeekSlider: isDraggedSeekSlider,
            isSeeking: $isSeeking,
            isSeekingByDoubleTap: $isSeekingByDoubleTap,
            seekerThumbImageSize: $seekerThumbImageSize,
            thumbnailsFrames: $thumbnailsFrames,
            draggingImage: $draggingImage
          )
          TimeCodes(UIControlsProps: $UIControlsProps)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .opacity(isSeeking || controlsVisible || isSeekingByDoubleTap ? 1 : 0)
        .animation(.easeInOut(duration: 0.35), value: isSeeking || controlsVisible || isSeekingByDoubleTap)
        HStack {
          Spacer()
          Menus(options: options != [:] ? options : defaultOptions, controls: controls, color: UIControlsProps?.menus.color)
          FullScreen(fullScreen: $isFullScreen, color: UIControlsProps?.fullScreen.color, action: {
            controls.toggleFullScreen()
            timeoutWorkItem?.cancel()
            
            if (isFullScreen) {
              isFullScreen = false
            } else {
              isFullScreen = true
            }
            
            if (player.timeControlStatus == .playing) {
              scheduleHideControls()
            }
          })
        }
        .padding(.bottom, 12)
        .padding(.trailing, 12)
        .padding(.leading, 12)
        .opacity(controlsVisible && !isSeeking && !isSeekingByDoubleTap ? 1 : 0)
      }
    }
  }
  
  @ViewBuilder
  func PlaybackControls() -> some View {
    Circle()
      .fill(.black.opacity(0.50))
      .frame(width: 60, height: 60)
      .overlay(
        Group {
          if isFinishedPlaying {
            Button(action: resetPlaybackStatus) {
              Image(systemName: "gobackward")
                .font(.system(size: 35))
                .foregroundColor(Color(uiColor: UIControlsProps?.playback.color ?? .white))
            }
            
          } else {
            if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
              CustomLoading(color: UIControlsProps?.loading.color)
            } else {
              CustomPlayPauseButton(
                action: { isPlaying in
                  controls.togglePlayback()
                  onPlayPauseStatus()
                  if (isPlaying) {
                    player.rate = rate
                  }
                },
                isPlaying: autoPlay,
                frame: .init(origin: .zero, size: .init(width: 30, height: 30)),
                color: UIControlsProps?.playback.color?.cgColor
              )
              .onAppear {
                scheduleHideControls()
              }
            }
          }
        }
        
      )
      .frame(width: 60, height: 60)
      .opacity(controlsVisible && !isSeeking && !isSeekingByDoubleTap ? 1 : 0)
  }
  
  private func onPlayPauseStatus() {
    if (player.timeControlStatus == .playing) {
      if let timeoutWorkItem {
        timeoutWorkItem.cancel()
      }
    } else {
      scheduleHideControls()
    }
  }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.35)) {
            controlsVisible.toggle()
        }
        
        if controlsVisible {
            scheduleHideControls()
        }
    }
    
    private func scheduleHideControls() {
        if let timeoutWorkItem {
            timeoutWorkItem.cancel()
        }
        
        if (player.timeControlStatus == .playing) {
            timeoutWorkItem = .init(block: {
                withAnimation(.easeInOut(duration: 0.35)) {
                    controlsVisible = false
                }
            })
            
            
            if let timeoutWorkItem {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: timeoutWorkItem)
            }
        }
    }
        
    private func generatingThumbnailsFrames(_ url: String) {
        Task.detached { [self] in
            let asset = AVAsset(url: URL(string: url)!)
            
            do {
                let totalDuration = asset.duration.seconds
                var framesTimes: [NSValue] = []
                
                // Generate thumbnails frames
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = .init(width: 150, height: 100)
                
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
                    
                    DispatchQueue.main.async { [self] in
                        let uiImage = UIImage(cgImage: cgImage)
                        thumbnailsFrames.append(uiImage)
                    }
                    
                }
            }
        }
    }
    
    private func forwardTime(_ timeToChange: Double) {
        guard let currentItem = player.currentItem else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        
        let newTime = max(currentTime + timeToChange, 0)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                    toleranceBefore: .zero,
                    toleranceAfter: .zero,
                    completionHandler: { _ in })
    }
    
    private func backwardTime(_ timeToChange: Double) {
        guard let currentItem = player.currentItem else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = max(currentTime - timeToChange, 0)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                    toleranceBefore: .zero,
                    toleranceAfter: .zero,
                    completionHandler: { _ in })
    }
    
    private func resetPlaybackStatus() {
        isFinishedPlaying = false
        
        sliderProgress = .zero
        lastDraggedProgresss = .zero

        player.seek(to: .zero, completionHandler: { completed in
            if (completed) {
                player.play()
                scheduleHideControls()
            }
        })
    }
}

@available(iOS 14.0, *)
struct DoubleTapManager : View {
  var onTapBackward: (Int) -> Void
  var onTapForward: (Int) -> Void
  var isFinished: () -> Void
  var advanceValue: Int
  var suffixAdvanceValue: String
  
  var body: some View {
    ZStack {
      Color(.clear).opacity(VariantPercent.p10)
      VStack {
        HStack(spacing: StandardSizes.large55) {
          DoubleTapSeek(onTap:  onTapBackward, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: isFinished)
          DoubleTapSeek(isForward: true, onTap:  onTapForward, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: isFinished)
        }
      }
    }
    .edgesIgnoringSafeArea(Edge.Set.all)
  }
}
