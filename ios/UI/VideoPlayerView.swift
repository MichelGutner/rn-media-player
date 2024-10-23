//
//  VideoPlayerView.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 22/02/24.
//

import SwiftUI
import AVKit
import Combine

@available(iOS 14.0, *)
struct VideoPlayerView: View {
    @Namespace private var animationNamespace
    
    @ObservedObject private var playbackObserver = PlaybackObserver()
    var player: AVPlayer
    var bounds: CGRect
    @Binding var autoPlay: Bool
    @State var options: NSDictionary? = [:]
    var controls: PlayerControls
    var thumbNailsProps: NSDictionary? = [:]
    var enterInFullScreenWhenDeviceRotated = false
    var videoGravity: AVLayerVideoGravity
    @Binding var UIControlsProps: HashableUIControls?
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
  
  var releaseResources: () -> Void
    
    
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
//            .overlay(
//                DoubleTapManager(
//                  onTapBackward: { value in
//                    backwardTime(Double(value))
//                    isSeekingByDoubleTap = true
//                  },
//                  onTapForward: { value in
//                    forwardTime(Double(value))
//                    isSeekingByDoubleTap = true
//                  },
//                  isFinished: {
//                    isSeekingByDoubleTap = false
//                  },
//                  advanceValue: tapToSeek?["value"] as? Int ?? 15,
//                  suffixAdvanceValue: tapToSeek?["suffixLabel"] as? String ?? "seconds"
//                )
//            )
            .onAppear {
              setupNotifications()
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
            .onReceive(playbackObserver.$deviceOrientation, perform: { isPortrait in
              if (!isPortrait) {
                isFullScreen = true
              }
            })
            .onTapGesture {
              withAnimation {
                toggleControls()
              }
            }
            .overlay(
              Group {
                ViewControllers(geometry: geometry)
                  .onAppear {
                    scheduleHideControls()
                  }
              }
            )
            .overlay(
              PlayPauseControl()
            )
        }
      }
    }
    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    .preferredColorScheme(.dark)
    .onAppear {
      thumbnailsFrames.removeAll()
      
      if let thumbNailsEnabled = thumbNailsProps?["enabled"] as? Bool {
        if let thumbnailsUrl = thumbNailsProps?["url"] as? String, thumbNailsEnabled {
          generatingThumbnailsFrames(thumbnailsUrl)
        }
      }
    }
    .onDisappear {
      releaseResources()
    }
  }
    
    @ViewBuilder
  func ViewControllers(geometry: GeometryProxy) -> some View {
    VStack {
      Spacer()
      HStack(alignment: .bottom) {
//        Thumbnails(
//          player: player,
//          geometry: geometry,
//          UIControlsProps: $UIControlsProps,
//          thumbnails: .constant(thumbNailsProps),
//          sliderProgress: $sliderProgress,
//          isSeeking: $isSeeking,
//          draggingImage: $draggingImage
//        )
//        .padding(.bottom, 12)
//        Spacer()
      }
      HStack {

      }
      .padding(.horizontal, 12)
      .padding(.bottom, 4)
      .opacity(isSeeking || controlsVisible || isSeekingByDoubleTap ? 1 : 0)
      .animation(.easeInOut(duration: 0.35), value: isSeeking || controlsVisible || isSeekingByDoubleTap)
      HStack {
        Spacer()
//        Menus(options: options, controls: controls, color: UIControlsProps?.menus.color)
        FullScreen(fullScreen: $isFullScreen, color: UIControlsProps?.fullScreen.color, action: {
//          controls.toggleFullScreen()
          toggleFullScreen()
          timeoutWorkItem?.cancel()
//          
//          if (isFullScreen) {
//            isFullScreen = false
//          } else {
//            isFullScreen = true
//          }
          
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
  
  @ViewBuilder
  func PlayPauseControl() -> some View {
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
//              CustomPlayPauseButton(
//                action: { isPlaying in
//                  controls.togglePlayback()
//                  onPlayPauseStatus()
//                  if (isPlaying) {
//                    if (rate > 0.0) {
//                      player.rate = rate
//                    }
//                  }
//                },
//                isPlaying: player.timeControlStatus == .playing,
//                frame: .init(origin: .zero, size: .init(width: 30, height: 30)),
//                color: UIControlsProps?.playback.color?.cgColor
//              )
//              .onAppear {
//                scheduleHideControls()
//              }
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
  
  private func setupNotifications() {
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
  
 private func toggleFullScreen() {
    if isFullScreen {
      exitOnFullscreen()
    } else {
      enterOnFullscreen()
    }
    
//    if autoOrientationOnFullscreen {
      DispatchQueue.main.async {
        if #available(iOS 16.0, *) {
          guard let windowSceen = getWindowScene() else { return }
          if windowSceen.interfaceOrientation == .portrait && self.isFullScreen {
            windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
          } else {
            windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
          }
        } else {
          if UIDevice.current.orientation == .portrait && self.isFullScreen {
            let orientation = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(orientation, forKey: "orientation")
          } else {
            let orientation = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(orientation, forKey: "orientation")
          }
        }
      }
//    }
  }
  
  private func enterOnFullscreen() {
    self.isFullScreen = true
  }
  
  private func exitOnFullscreen() {
    self.isFullScreen = false
//    uiView.frame = bounds
  }
}

extension View {
    func getWindowScene() -> UIWindowScene? {
        return UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene
    }
}
