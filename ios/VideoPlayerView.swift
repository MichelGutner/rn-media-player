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
  @State private var isLoading: Bool = false
  @State private var title: String = ""
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
  
  @State private var downloadProgress: Float = 0.0
  @State private var showActionSheetFileManager = false
  
  @State private var seekerThumbImageSize: CGSize = .init(width: 15, height: 15)
  
  var size: CGSize
  var safeAreaInsets: EdgeInsets
  var onTapFullScreenControl: (Bool) -> Void
  var onTapSettingsControl: () -> Void
  
  private var fileManager = PlayerFileManager()
  
  
  init(
    size: CGSize,
    safeAreaInsets: EdgeInsets,
    player: AVPlayer,
    isLoading: Bool,
    title: String,
    playbackFinished: Bool,
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
    self.safeAreaInsets = safeAreaInsets
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
    _title = State(initialValue: title)
    _isLoading = State(initialValue: isLoading)
  }
  
  var body: some View {
    VStack {
      let videoPlayerSize: CGSize = .init(width: size.width, height: size.height)
      
      ZStack {
        Group {
          if isLoading {
            CustomLoading(config: [:])
              .edgesIgnoringSafeArea(isFullScreen ? Edge.Set.all : [])
          } else {
            CustomVideoPlayer(player: player, videoGravity: videoGravity)
              .edgesIgnoringSafeArea(isFullScreen ? Edge.Set.all : [])
              .overlay(
                Rectangle()
                  .fill(Color.black.opacity(0.4))
                  .opacity(showPlayerControls || isDraggingSlider ? 1 : 0)
                  .animation(.easeInOut(duration: AnimationDuration.s035), value: isDraggingSlider)
                  .overlay(
                    Group {
                      //                  if isLoading {
                      //                    CustomLoading(config: [:])
                      //                  } else {
                      PlaybackControls()
                      //                  }
                    }
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
                withAnimation(.easeOut(duration: AnimationDuration.s035)) {
                  showPlayerControls.toggle()
                }
                
                if player.timeControlStatus == .playing {
                  timeoutControls()
                }
              }
              .overlay(
                VStack {
                  HeaderControls()
                    .opacity(showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap ? 1 : 0)
                    .animation(.easeInOut(duration: AnimationDuration.s035), value: showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap)
                  Spacer()
                  VideoSeekerView()
                  HStack {
                    Spacer()
                    DownloadControl()
                    SettingsControl()
                    FullScreenControl()
                  }
                  .padding(.top, -StaticSize.s8)
                  .opacity(showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap ? 1 : 0)
                  .animation(.easeInOut(duration: AnimationDuration.s035), value: showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap)
                }
                  .padding(.leading)
                  .padding(.trailing)
                  .padding(.bottom, safeAreaInsets.bottom + StaticSize.s16)
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
                        self.notificationPostModal(userInfo: ["\(SettingsOption.speeds)Opened": false])
                        self.notificationPostModal(userInfo: ["\(SettingsOption.qualities)Opened": false])
                        self.notificationPostModal(userInfo: ["\(SettingsOption.moreOptions)Opened": false])
                      },
                      modalContent: {
                        Group {
                          if openedOptionsQuality {
                            OptionsContentView(
                              size: size,
                              data: videoQualities,
                              onSelected: { [self] item in
                                selectedQuality = item.name
                                self.notificationPostModal(userInfo: ["optionsQualitySelected": item.name, "\(SettingsOption.qualities)Opened": false, "qualityUrl": item.value])
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
                                self.notificationPostModal(userInfo: ["optionsSpeedSelected": item.name, "\(SettingsOption.speeds)Opened": false, "speedRate": Float(item.value) as Any])
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
                                let option = SettingsOption(rawValue: item)
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
        }
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
        Text(title).font(.system(size: 12)).foregroundColor(.white)
        Spacer()
      }
    }

  @ViewBuilder
  func VideoSeekerThumbnailView() -> some View {
    let calculatedWidthThumbnailSizeByWidth = calculateSizeByWidth(StaticSize.s200, VariantPercent.p40)
    let calculatedHeightThumbnailSizeByWidth = calculateSizeByWidth(StaticSize.s100, VariantPercent.p40)
    
    let thumbSize: CGSize = .init(width: calculatedWidthThumbnailSizeByWidth, height: calculatedHeightThumbnailSizeByWidth)
  
    HStack {
      if let draggingImage {
        VStack {
          Image(uiImage: draggingImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: thumbSize.width, height: thumbSize.height)
            .clipShape(RoundedRectangle(cornerRadius: CorneRadious.c16, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: CorneRadious.c16, style: .continuous)
                .stroke(.blue, lineWidth: 2)
            )
          Text(stringFromTimeInterval(interval: TimeInterval(truncating: (sliderProgress * duration) as NSNumber)))
            .font(.caption)
            .foregroundColor(.white)
            .fontWeight(.semibold)
        }
      } else {
        RoundedRectangle(cornerRadius: CorneRadious.c16, style: .continuous)
          .fill(.black)
          .overlay(
            RoundedRectangle(cornerRadius: CorneRadious.c16, style: .continuous)
              .stroke(.white, lineWidth: 2)
          )
      }
    }
    .frame(width: thumbSize.width, height: thumbSize.height)
    .opacity(isDraggingSlider ? 1 : 0)
    .offset(x: sliderProgress * (size.width - thumbSize.width))
    .animation(.easeInOut(duration: AnimationDuration.s035), value: isDraggingSlider)
    
  }
  
  @ViewBuilder
  func VideoSeekerView() -> some View {
    VStack(alignment: .leading) {
      VideoSeekerThumbnailView()
        .padding(.bottom, 16)
      HStack {
        ZStack(alignment: .leading) {
          Rectangle()
            .fill(Color.gray).opacity(0.5)
            .frame(width: size.width - seekerThumbImageSize.width)
            .cornerRadius(8)
          
          Rectangle()
            .fill(Color.white)
            .frame(width: buffering * (size.width - seekerThumbImageSize.width))
            .cornerRadius(8)
          
          Rectangle()
            .fill(Color.blue)
            .frame(width: calculateSliderWidth())
            .cornerRadius(8)
          
          HStack {}
            .overlay(
              Circle()
                .fill(Color.blue)
                .frame(width: seekerThumbImageSize.width, height: seekerThumbImageSize.height)
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
      .animation(.easeInOut(duration: AnimationDuration.s035), value: showPlayerControls || isSeekingByDoubleTap || isSeeking)
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
          Image(systemName: playPauseimageName)
            .foregroundColor(.white)
            .font(.system(size: size30))
            .padding(size16)
        }
        .background(Color(.black).opacity(0.4))
        .cornerRadius(.infinity)
        Spacer()
      }
      .fixedSize(horizontal: true, vertical: true)
      Spacer()
    }
    .opacity(showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap ? 1 : 0)
    .animation(.easeInOut(duration: AnimationDuration.s035), value: showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap)
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
        withAnimation(.linear(duration: AnimationDuration.s035)) {
          openedSettingsModal = true
          notificationPostModal(userInfo: ["opened": openedSettingsModal])
        }
    }) {
      DefaultImage("gear")
    }
    .fixedSize(horizontal: true, vertical: true)
  }
  
  @ViewBuilder
  func DownloadControl() -> some View {
    let cached = PlayerFileManager().videoCached(title: title)
    Button (action: {
      showActionSheetFileManager = true
    }) {
      VStack {
        Image(systemName: "arrow.down")
          .foregroundColor(.white)
          .font(.system(size: 20))
          .padding(8)
        
        ZStack(alignment: .leading) {
          Rectangle()
            .fill(cached.fileExist ? Color.blue : .white)
            .frame(width: 30, height: 3)
            .cornerRadius(16)
            .padding(.top, -15)
          
          Rectangle()
            .fill(Color.blue)
            .frame(width: CGFloat(downloadProgress / 100) * 30, height: 3)
            .cornerRadius(16)
            .padding(.top, -15)
        }
        
      }
    }
    .actionSheet(isPresented: $showActionSheetFileManager) {
        let buttons: [ActionSheet.Button]
        
        if !cached.fileExist {
            buttons = [
                .default(Text("Baixar")) {
                    fileManager.downloadFile(from: urlOfCurrentPlayerItem(player: player)!, title: title, onProgress: { progress in
                        self.downloadProgress = progress
                    }, completion: { response, error in
                      print("resp \(String(describing: response)) error: \(String(describing: error))")
                    })
                },
                .cancel()
            ]
        } else {
            buttons = [
                .destructive(Text("Remover")) {
                  fileManager.deleteFile(title: title, completetion: { message, error in
                    print("message: \(message), error: \(String(describing: error))")
                    self.downloadProgress = .zero
                  })
                },
                .cancel(Text("Cancelar"))
            ]
        }
        
      return ActionSheet(title: Text(!cached.fileExist ? "Deseja baixar o video?" : "Este vídeo já foi baixado deseja remover o video?"), buttons: buttons)
    }

  }
  
  @ViewBuilder
  func DefaultImage(_ name: String) -> some View {
    Image(systemName: name)
      .font(.system(size: 20))
      .foregroundColor(.white)
      .padding(8)
  }
}

// MARK: -- Private Functions
@available(iOS 13.0, *)
extension VideoPlayerView {
  private func urlOfCurrentPlayerItem(player : AVPlayer) -> URL? {
    return ((player.currentItem?.asset) as? AVURLAsset)?.url
  }
  private func calculateSliderWidth() -> CGFloat {
      let maximumWidth = (size.width - seekerThumbImageSize.width)
      let calculatedWidth = maximumWidth * CGFloat(sliderProgress)
      return min(maximumWidth, max(0, calculatedWidth))
  }

  private func timeoutControls() {
    if let timeoutTask {
      timeoutTask.cancel()
    }
    
    timeoutTask = .init(block: {
      withAnimation(.easeInOut(duration: AnimationDuration.s035)) {
        showPlayerControls = false
      }
    })
    
    if let timeoutTask {
      DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: timeoutTask)
    }
  }
    
  private func updatePlayerTime(_ time: CGFloat) {
    guard let currentItem = player.currentItem else {
      self.isLoading = true
      return
    }
    
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
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
        if isActiveLoop {
          resetPlaybackStatus()
        }
      })
      
    } else {
      isFinishedPlaying = false
      notificationPostPlaybackInfo(userInfo: ["playbackFinished": false])
      updatePlayPauseImage()
    }
    self.isLoading = false
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
      withAnimation(.easeInOut(duration: AnimationDuration.s035)) {
        playPauseimageName = "gobackward"
      }
    } else {
      withAnimation(.easeInOut(duration: AnimationDuration.s035)) {
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
  
  private func optionsItemSelected(_ item: SettingsOption) {
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
  var isLoading: Bool
  var title: String
  var playbackFinished: Bool
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
      let safeAreaInsets = $0.safeAreaInsets
      
      VideoPlayerView(
        size: size,
        safeAreaInsets: safeAreaInsets,
        player: player,
        isLoading: isLoading,
        title: title,
        playbackFinished: playbackFinished,
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
