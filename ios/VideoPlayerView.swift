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
  @ObservedObject private var playbackObserver = PlaybackObserver()
  @State private var player: AVPlayer
  @State private var showPlayerControls: Bool = false
  @State private var isPlaying: Bool? = nil
  @State private var timeoutTask: DispatchWorkItem?
  @State private var playPauseimageName: String = "pause.fill"
  @State private var timeObserver: Any? = nil
  
  @State private var openedSettingsModal: Bool = false
  @State private var openedOptionsQuality: Bool = false
  @State private var openedOptionsSpeed: Bool = false
  @State private var openedOptionsMoreOptions: Bool = false
  
  @State private var optionsData: [HashableData] = []
  @State private var initialSelectedItem: String = ""
  @State private var initialQualitySelected: String = ""
  
  @State private var initialSpeedSelected: String = ""
  
  @State private var selectedQuality: String = ""
  @State private var selectedSpeed: String = ""

  @State private var videoQualities: [HashableData] = []
  @State private var videoSpeeds: [HashableData] = []
  @State private var videoSettings: [HashableData] = []
  

  
  @GestureState private var isDraggingSlider: Bool = false
  @State private var sliderProgress = 0.0
  @State private var lastDraggedProgress: CGFloat = 0
  @State private var isSeeking: Bool = false
  @State private var buffering: Double = 0.0
  @State private var isFinishedPlaying: Bool = false
  @State private var isObservedAdded: Bool = false
  @State private var isSeekingByDoubleTap: Bool = false
  
  @State private var thumbnailsFrames: [UIImage] = []
  @State private var draggingImage: UIImage?
  
  @State private var duration: Double = 0
  @State private var currentTime: Double = 0
  @State private var videoPlayerSize: CGSize!
  
  @State private var isFullScreen: Bool = false
  
  @State private var isActiveAutoPlay: Bool = false
  @State private var isActiveLoop: Bool = false
  @State private var videoGravity: AVLayerVideoGravity!
  @State private var interval = CMTime(value: 1, timescale: 2)
  
  var size: CGSize
  var onTapFullScreenControl: (Bool) -> Void
  var onTapSettingsControl: () -> Void
  
  
  init(
    size: CGSize,
    player: AVPlayer,
    currentTime: Double,
    duration: Double,
    playbackFinished: Bool,
    buffering: Double,
    thumbnails: [UIImage],
    onTapFullScreenControl: @escaping (Bool) -> Void,
    isFullScreen: Bool,
    videoSettings: [HashableData],
    onTapSettingsControl: @escaping () -> Void,
    videoQualities: [HashableData],
    initialQualitySelected: String,
    videoSpeeds: [HashableData],
    initialSpeedSelected: String,
    selectedQuality: String,
    selectedSpeed: String,
    settingsModalOpened: Bool,
    openedOptionsQualities: Bool,
    openedOptionsSpeed: Bool,
    openedOptionsMoreOptions: Bool,
    isActiveAutoPlay: Bool,
    isActiveLoop: Bool,
    videoGravity: AVLayerVideoGravity,
    sliderProgress: Double,
    lastDraggedProgress: Double,
    isPlaying: Bool?
  ) {
    self.size = size
    _player = State(initialValue: player)
    self.onTapFullScreenControl = onTapFullScreenControl
    self.onTapSettingsControl = onTapSettingsControl
    _thumbnailsFrames = State(initialValue: thumbnails)
    _isFullScreen = State(wrappedValue: isFullScreen)
    _videoQualities = State(initialValue: videoQualities)
    _videoSpeeds = State(initialValue: videoSpeeds)
    _videoSettings = State(initialValue: videoSettings)
    _initialQualitySelected = State(initialValue: selectedQuality.isEmpty ? initialQualitySelected : selectedQuality)
    _initialSpeedSelected = State(initialValue: selectedSpeed.isEmpty ? initialSpeedSelected : selectedSpeed)
    _openedSettingsModal = State(initialValue: settingsModalOpened)
    _openedOptionsQuality = State(initialValue: openedOptionsQualities)
    _openedOptionsSpeed = State(initialValue: openedOptionsSpeed)
    _openedOptionsMoreOptions = State(initialValue: openedOptionsMoreOptions)
    _playbackObserver = ObservedObject(initialValue: PlaybackObserver())
    _isActiveAutoPlay = State(initialValue: isActiveAutoPlay)
    _isActiveLoop = State(initialValue: isActiveLoop)
    _videoGravity = State(wrappedValue: videoGravity)
    _isFinishedPlaying = State(initialValue: playbackFinished)
    _isPlaying = State(wrappedValue: isPlaying)
    _timeObserver = State(initialValue: nil)
  }
  
  var body: some View {
    VStack {
      let videoPlayerSize: CGSize = .init(width: size.width, height: size.height)
      ZStack {
        CustomVideoPlayer(player: player, videoGravity: videoGravity)
          .edgesIgnoringSafeArea(isFullScreen ? Edge.Set.all : [])
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
                isSeekingByDoubleTap = true
              },
              onTapForward: { value in
                forwardTime(Double(value))
                isSeekingByDoubleTap = true
              },
              isFinished: {
                isSeekingByDoubleTap = false
              },
              advanceValue: 15,
              suffixAdvanceValue: "seconds"
            )
          )
          .onTapGesture {
            withAnimation(.easeOut(duration: 0.35)) {
              showPlayerControls.toggle()
            }
            
            if isPlaying == true {
              timeoutControls()
            }
          }
          .overlay(
            VStack {
              HeaderControls()
                .opacity(showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap)
              Spacer()
              VideoSeekerView()
              HStack {
                Spacer()
                SettingsControl()
                FullScreenControl()
              }
              .opacity(showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap ? 1 : 0)
              .animation(.easeInOut(duration: 0.2), value: showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap)
            }
              .padding(.leading)
              .padding(.trailing)
          )
          .overlay(
            Group {
              if openedSettingsModal {
                ModalViewController(
                  onModalAppear: {},
                  onModalDisappear: {
                    resetModalState()
                  },
                  onModalCompletion: { [self] in
                    openedSettingsModal = false
                    openedOptionsMoreOptions = false
                    self.notificationPostModal(userInfo: ["opened": openedSettingsModal])
                    self.notificationPostModal(userInfo: ["\(ESettingsOptions.speeds)Opened": false])
                    self.notificationPostModal(userInfo: ["\(ESettingsOptions.qualities)Opened": false])
                    self.notificationPostModal(userInfo: ["\(ESettingsOptions.moreOptions)Opened": false])
                  },
                  modalContent: {
                    Group {
                      if openedOptionsQuality {
                        OptionsContentView(
                          size: size,
                          data: videoQualities,
                          onSelected: { [self] item in
                            selectedQuality = item.name
                            self.notificationPostModal(userInfo: ["optionsQualitySelected": item.name, "\(ESettingsOptions.qualities)Opened": false, "qualityUrl": item.value])
                            resetModalState()
                          },
                          initialSelectedItem: initialQualitySelected,
                          selectedItem: selectedQuality
                        )
                      } else if openedOptionsSpeed {
                        OptionsContentView(
                          size: size,
                          data: videoSpeeds,
                          onSelected: { [self] item in
                            selectedSpeed = item.name
                            self.notificationPostModal(userInfo: ["optionsSpeedSelected": item.name, "\(ESettingsOptions.speeds)Opened": false, "speedRate": Float(item.value) as Any])
                            resetModalState()
                            updatePlayPauseImage()
                          },
                          initialSelectedItem: initialSpeedSelected,
                          selectedItem: selectedSpeed
                        )
                      } else if openedOptionsMoreOptions {
                        MoreOptionsContentView(
                          isActiveAutoPlay: isActiveAutoPlay,
                          isActiveLoop: isActiveLoop,
                          onTapAutoPlay: { isActive in
                            isActiveAutoPlay = isActive
                            self.notificationPostModal(userInfo: ["optionsAutoPlay": isActive])
                          },
                          onTapLoop: { isActive in
                            isActiveLoop = isActive
                            self.notificationPostModal(userInfo: ["optionsLoop": isActive])
                          }
                        )
                      } else {
                        SettingsContentView(
                          settingsData: videoSettings,
                          onSettingSelected: { [self] item in
                            let option = ESettingsOptions(rawValue: item)
                            self.optionsItemSelected(option!)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                              if let optionItem = option {
                                self.notificationPostModal(userInfo: ["\(optionItem)Opened": true])
                              }
                            })
                          })
                        
                      }
                    }
                  })
              }
            }
          )
      }
      .frame(width: videoPlayerSize.width, height: videoPlayerSize.height)
      
    }
    .onAppear {
      guard !isObservedAdded else { return }
      guard let currentItem = player.currentItem else { return }
      let currentTime = currentItem.currentTime().seconds
      let duration = currentItem.duration.seconds
      
      if !duration.isNaN {
        self.duration = duration
        self.currentTime = currentTime
        
        sliderProgress = currentTime / duration
        lastDraggedProgress = sliderProgress
        
        let loadedTimeRanges = currentItem.loadedTimeRanges
        if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
          let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
          let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
          let bufferedEnd = CMTimeGetSeconds(firstTimeRange.end)
          buffering = (bufferedStart + bufferedDuration) / duration
          notificationPostPlaybackInfo(userInfo: ["buffering": bufferedEnd])
        }
      }
      
      if isActiveAutoPlay {
        if isPlaying == nil {
          player.play()
        }
      } else {
        player.pause()
      }
      
      timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
        updatePlayerTime(time.seconds)
      }
      
      updatePlayPauseImage()
      
      NotificationCenter.default.addObserver(
        playbackObserver,
        selector: #selector(PlaybackObserver.playbackItem(_:)),
        name: .AVPlayerItemNewAccessLogEntry,
        object: player.currentItem
      )
      
      NotificationCenter.default.addObserver(
        playbackObserver,
        selector: #selector(PlaybackObserver.itemDidFinishPlaying(_:)),
        name: .AVPlayerItemDidPlayToEndTime,
        object: player.currentItem
      )
      
      NotificationCenter.default.addObserver(
        playbackObserver,
        selector: #selector(PlaybackObserver.getThumbnailFrames(_:)),
        name: Notification.Name("frames"),
        object: nil
      )

      isObservedAdded = true
    }
    .onReceive(playbackObserver.$isFinishedPlaying) { [self] finished in
      if finished {
        if isActiveLoop {
          player.seek(to: .zero)
          return
        }
        
        onFinished()
      }
    }
    .onReceive(playbackObserver.$thumbnailsFrames) { frames in
        DispatchQueue.main.async {
            if !frames.isEmpty {
              self.thumbnailsFrames = frames
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
          DefaultImage("arrow.left")
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
          Text(stringFromTimeInterval(interval: TimeInterval(truncating: (sliderProgress * duration) as NSNumber)))
            .font(.caption)
            .foregroundColor(.white)
            .fontWeight(.semibold)
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
    .offset(x: sliderProgress * (size.width - thumbSize.width))
    .animation(.easeInOut(duration: 0.2), value: isDraggingSlider)
    
  }
  
  @ViewBuilder
  func VideoSeekerView() -> some View {
//    let calculateSizeDurationText = calculateSizeByWidth(size8, variantPercent10)

    VStack(alignment: .leading) {
      VideoSeekerThumbnailView()
        .padding(.bottom, 8)
      HStack {
          ZStack(alignment: .leading) {
              Rectangle()
                  .fill(Color.gray).opacity(0.5)
                  .frame(width: size.width)
                  .cornerRadius(8)
              
              Rectangle()
                  .fill(Color.white)
                  .frame(width: buffering * size.width)
                  .cornerRadius(8)
              
              Rectangle()
                  .fill(Color.blue)
                  .frame(width: calculateSliderWidth())
                  .cornerRadius(8)
              
              HStack {}
                  .overlay(
                      Circle()
                          .fill(Color.blue)
                          .frame(width: 15, height: 15)
                          .frame(width: 50, height: 50)
                          .opacity(isSeekingByDoubleTap ? 0.001 : 1)
                          .contentShape(Rectangle())
                          .offset(x: calculateSliderWidth())
                          .gesture(
                              DragGesture()
                                  .updating($isDraggingSlider, body: { _, out, _ in
                                      out = true
                                  })
                                  .onChanged({ value in
                                      let translationX = value.translation.width
                                      let calculatedProgress = (translationX / size.width) + lastDraggedProgress
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
                                        let tolerance = CMTime(seconds: 0.1, preferredTimescale: Int32(NSEC_PER_SEC))
                                        
                                          if targetTime < duration {
                                              isFinishedPlaying = false
                                              updatePlayPauseImage()
                                          }
                                        
                                        player.seek(to: targetCMTime, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: { completed in
                                              isSeeking = false
                                          })
                                      }
                                      
                                      if isPlaying == true {
                                          timeoutControls()
                                      }
                                  })
                          )
                  )
          }
          .frame(height: 3)
      }
      .opacity(showPlayerControls || isSeeking || isSeekingByDoubleTap ? 1 : 0)
      .animation(.easeInOut(duration: 0.2), value: showPlayerControls || isSeekingByDoubleTap || isSeeking)

    }
  }
  
  @ViewBuilder
  func PlaybackControls() -> some View {
    
    VStack {
      Spacer()
      HStack {
        Spacer()
        Button(action: {
          onPlaybackManager()
        }) {
//          if isLoading {
//            LoadingManager(config: [:])
//          } else {
            Image(systemName: playPauseimageName)
              .foregroundColor(.white)
              .font(.system(size: size30))
              .padding(size16)
//          }
        }
        .background(Color(.black).opacity(0.4))
        .cornerRadius(.infinity)
        Spacer()
      }
      .fixedSize(horizontal: true, vertical: true)
      Spacer()
    }
    .opacity(showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap ? 1 : 0)
    .animation(.easeInOut(duration: 0.2), value: showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap)
  }
  
  @ViewBuilder
  func FullScreenControl() -> some View {

//    let color = fullScreenConfig?["color"] as? String
//    let isHidden = fullScreenConfig?["hidden"] as? Bool
    
    Button (action: {
      isFullScreen.toggle()
      self.onTapFullScreenControl(isFullScreen)
    }) {
      DefaultImage(isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
    }
//    .foregroundColor(Color(transformStringIntoUIColor(color: color)))
    .rotationEffect(.init(degrees: 90))
//    .opacity(isHidden ?? false ? 0 : 1)
  }
  
  @ViewBuilder
  func SettingsControl() -> some View {
    Button(action: {
        withAnimation(.linear(duration: 0.2)) {
          openedSettingsModal = true
          notificationPostModal(userInfo: ["opened": openedSettingsModal])
        }
    }) {
      DefaultImage("gear")
    }
    .fixedSize(horizontal: true, vertical: true)
  }
  
  @ViewBuilder
  func DefaultImage(_ name: String) -> some View {
    Image(systemName: name)
      .font(.system(size: 25))
      .foregroundColor(.white)
      .padding(8)
  }
}

// MARK: -- Private Functions
@available(iOS 13.0, *)
extension VideoPlayerView {
  private func calculateSliderWidth() -> CGFloat {
      let maximumWidth = size.width
      let calculatedWidth = maximumWidth * CGFloat(sliderProgress)
      return min(maximumWidth, max(0, calculatedWidth))
  }

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
    
  private func updatePlayerTime(_ time: CGFloat) {
    guard let currentItem = player.currentItem else { return }

    currentTime = time
    duration = currentItem.duration.seconds
    let calculatedProgress = currentTime / duration
    
    let loadedTimeRanges = currentItem.loadedTimeRanges
    if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
      let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
      let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
      let bufferedEnd = CMTimeGetSeconds(firstTimeRange.end)
      buffering = (bufferedStart + bufferedDuration) / duration
      notificationPostPlaybackInfo(userInfo: ["buffering": bufferedEnd])
    }
    notificationPostPlaybackInfo(userInfo: ["currentTime": currentTime, "duration": duration])

      if !isSeeking && time < currentItem.duration.seconds {
        sliderProgress = calculatedProgress
        lastDraggedProgress = sliderProgress
        notificationPostPlaybackInfo(userInfo: ["sliderProgress": calculatedProgress, "lastDraggedProgress": calculatedProgress])
      }
    
    if !isSeeking && time >= currentItem.duration.seconds {
      onFinished()
      print("tester")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
        if isActiveLoop {
          resetPlaybackStatus()
        }
      })
      
    } else {
      print("false")
      isFinishedPlaying = false
      notificationPostPlaybackInfo(userInfo: ["playbackFinished": false])
      updatePlayPauseImage()
    }
  }
  
  private func removePeriodicTimeObserver() {
    guard let timeObserver else { return }
    player.pause()
    player.removeTimeObserver(timeObserver)
    self.timeObserver = nil
  }
  
  private func onPlaybackManager() {
    if isFinishedPlaying {
      resetPlaybackStatus()
    } else {
      if player.timeControlStatus == .paused  {
        player.play()
        isPlaying = true
        timeoutControls()
      } else {
        player.pause()
        isPlaying = false
        if let timeoutTask {
          timeoutTask.cancel()
        }
      }
      notificationPostPlaybackInfo(userInfo: ["isPlaying": isPlaying])
    }
    updatePlayPauseImage()
    
    
  }
  
  private func updatePlayPauseImage() {
    if isFinishedPlaying {
      withAnimation(.easeInOut(duration: 0.35)) {
        playPauseimageName = "gobackward"
      }
    } else {
      withAnimation(.easeInOut(duration: 0.35)) {
        player.timeControlStatus == .paused ? (playPauseimageName = "play.fill") : (playPauseimageName = "pause.fill")
      }
      isFinishedPlaying = false
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
  
  private func resetModalState() {
    openedSettingsModal = false
    openedOptionsQuality = false
    openedOptionsSpeed = false
    openedOptionsMoreOptions = false
  }
  
  private func notificationPostModal(userInfo: [String: Any]) {
    NotificationCenter.default.post(name: Notification.Name("modal"), object: nil, userInfo: userInfo)
  }
  
  private func notificationPostPlaybackInfo(userInfo: [String: Any]) {
    NotificationCenter.default.post(name: Notification.Name("playbackInfo"), object: nil, userInfo: userInfo)
  }
  
  private func optionsItemSelected(_ item: ESettingsOptions) {
    switch(item) {
    case .qualities:
      openedOptionsQuality = true
      break
    case .speeds:
      openedOptionsSpeed = true
      break
    case .moreOptions:
      openedOptionsMoreOptions = true
      break
    }
  }
  
  private func onFinished() {
    isFinishedPlaying = true
    notificationPostPlaybackInfo(userInfo: ["playbackFinished": true])
    updatePlayPauseImage()
  }
  
  private func resetPlaybackStatus() {
    isFinishedPlaying = false
    
    sliderProgress = .zero
    lastDraggedProgress = .zero
    player.seek(to: .zero, completionHandler: {completed in
      if completed {
        player.play()
        updatePlayPauseImage()
        notificationPostPlaybackInfo(userInfo: ["playbackFinished": false])
      }
    })
  }
}

// MARK: -- CustomView
@available(iOS 13.0, *)
struct CustomView : View {
  var player: AVPlayer
  var currentTime: Double
  var duration: Double
  var playbackFinished: Bool
  var buffering: Double
  var videoGravity: AVLayerVideoGravity
  var thumbnails: [UIImage]
  var onTapFullScreenControl: (Bool) -> Void
  var isFullScreen: Bool
  var videoSettings: [HashableData]
  var onTapSettingsControl: () -> Void
  var videoQualities: [HashableData]
  var initialQualitySelected: String
  var videoSpeeds: [HashableData]
  var initialSpeedSelected: String
  var selectedQuality: String
  var selectedSpeed: String
  var settingsModalOpened: Bool
  var openedOptionsQualities: Bool
  var openedOptionsSpeed: Bool
  var openedOptionsMoreOptions: Bool
  var isActiveAutoPlay: Bool
  var isActiveLoop: Bool
  var sliderProgress: Double
  var lastDraggedProgress: Double
  var isPlaying: Bool?
  
  var body: some View {
    GeometryReader {
      let size = $0.size
      
      VideoPlayerView(
        size: size,
        player: player,
        currentTime: currentTime,
        duration: duration,
        playbackFinished: playbackFinished,
        buffering: buffering,
        thumbnails: thumbnails,
        onTapFullScreenControl: onTapFullScreenControl,
        isFullScreen: isFullScreen,
        videoSettings: videoSettings,
        onTapSettingsControl: onTapSettingsControl,
        videoQualities: videoQualities,
        initialQualitySelected: initialQualitySelected,
        videoSpeeds: videoSpeeds,
        initialSpeedSelected: initialSpeedSelected,
        selectedQuality: selectedQuality,
        selectedSpeed: selectedSpeed,
        settingsModalOpened: settingsModalOpened,
        openedOptionsQualities: openedOptionsQualities,
        openedOptionsSpeed: openedOptionsSpeed,
        openedOptionsMoreOptions: openedOptionsMoreOptions,
        isActiveAutoPlay: isActiveAutoPlay,
        isActiveLoop: isActiveLoop,
        videoGravity: videoGravity,
        sliderProgress: sliderProgress,
        lastDraggedProgress: lastDraggedProgress,
        isPlaying: isPlaying
      )
    }
  }
}


@available(iOS 13.0, *)
struct DoubleTapManager : View {
  var onTapBackward: (Int) -> Void
  var onTapForward: (Int) -> Void
  var isFinished: () -> Void
  var advanceValue: Int
  var suffixAdvanceValue: String
  
  var body: some View {
    ZStack {
      Color(.clear).opacity(variantPercent10)
      VStack {
        HStack(spacing: size60) {
          DoubleTapSeek(onTap:  onTapBackward, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: isFinished)
          DoubleTapSeek(isForward: true, onTap:  onTapForward, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: isFinished)
        }
      }
    }
    .edgesIgnoringSafeArea(Edge.Set.all)
  }
}
