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
  var onTapFullScreenControl: (Bool) -> Void
  var onTapSettingsControl: () -> Void
  
  @ObservedObject private var playbackObserver = PlaybackObserver()
  
  @State private var player: AVPlayer
  @State private var showPlayerControls: Bool = false
  @State private var isPlaying: Bool = true
  @State private var timeoutTask: DispatchWorkItem?
  @State private var playPauseimageName: String = "pause.fill"
  
  
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
  @State private var buffering = 0.0
  @State private var isFinishedPlaying: Bool = false
  @State private var isObservedAdded: Bool = false
  @State private var isSeekingByDoubleTap: Bool = false
  
  @State private var thumbnailsFrames: [UIImage] = []
  @State private var draggingImage: UIImage?
  
  @State private var playbackDuration: Double = 0
  @State private var videoPlayerSize: CGSize!
  
  @State private var isFullScreen: Bool = false
  
  @State private var isActiveAutoPlay: Bool = false
  @State private var isActiveLoop: Bool = false
  
  
  
  init(
    size: CGSize,
    player: AVPlayer,
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
    isActiveLoop: Bool
  ) {
    self.size = size
    self.player = player
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
            
            if isPlaying {
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
//              .padding(.top, 12)
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
                            //                        changePlaybackQuality(URL(string: item.value)!)
                            //                        qualityModalView.removeFromSuperview()
                            //                        isOpenedModal = false
                            self.notificationPostModal(userInfo: ["optionsSpeedSelected": item.name, "\(ESettingsOptions.speeds)Opened": false])
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
      
      if isActiveAutoPlay {
        player.play()
      } else {
        player.pause()
      }
      
      updateImage()
      player.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main) { [self] _ in
        updatePlayerTime()
      }
      
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
    .onReceive(playbackObserver.$isFinishedPlaying) { finished in
      if finished {
        print("testing")
        if isActiveLoop {
          player.seek(to: .zero)
          return
        }

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
    .offset(x: sliderProgress * (size.width - thumbSize.width))
    .animation(.easeInOut(duration: 0.2), value: isDraggingSlider)
    
  }
  
  @ViewBuilder
  func VideoSeekerView() -> some View {
    let calculateSizeDurationText = calculateSizeByWidth(size8, variantPercent10)

    VStack(alignment: .leading) {
      VideoSeekerThumbnailView()
        .padding(.bottom, 8)
      HStack {
        ZStack(alignment: .leading) {
          Rectangle()
            .fill(.gray).opacity(0.5)
            .frame(width: size.width)
            .cornerRadius(8)
          
          Rectangle()
            .fill(.red)
            .frame(width: size.width * sliderProgress)
            .cornerRadius(8)
          
          HStack {}
            .overlay(
              Circle()
                .fill(.red)
                .frame(width: 15, height: 15)
                .frame(width: 50, height: 50)
                .opacity(isSeekingByDoubleTap ? 0.001 : 1)
                .contentShape(Rectangle())
                .offset(x: size.width * sliderProgress)
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
        
//        Text(stringFromTimeInterval(interval: playbackDuration))
//          .font(.system(size: calculateSizeDurationText))
//          .foregroundColor(.white)
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
    if player.currentTime().seconds >= (currentIem.duration.seconds) {
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
}

// MARK: -- CustomView
@available(iOS 13.0, *)
struct CustomView : View {
  var player: AVPlayer
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
  
  var body: some View {
    GeometryReader {
      let size = $0.size
      
      VideoPlayerView(
        size: size,
        player: player,
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
        isActiveLoop: isActiveLoop
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
