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
  @ObservedObject private var playbackObserver = PlaybackObserver()
  @State private var player: AVPlayer
  @State private var menus: NSDictionary
    @State private var controlsCallback: Controls
  @State private var isLoading: Bool = false
  @State private var title: String = ""
  @State private var showPlayerControls: Bool = false
  @State private var isPlaying: Bool? = nil
  @State private var timeoutTask: DispatchWorkItem?
  @State private var timeObserver: Any? = nil
  
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
  @State private var downloadInProgress: Bool = false
  @State private var showActionSheetFileManager = false
  
  @State private var seekerThumbImageSize: CGSize = .init(width: 15, height: 15)
  @State private var doubleTapSeekValue: Int = 10
  @State private var suffixLabelDoubleTapSeek: String = "Seconds"
  @State private var isPresentToast: Bool = false
  
  @State private var controlsProps: HashableControllers? = .init(
    playbackControl: .init(dictionary: [:]),
    seekSliderControl: .init(dictionary: [:]),
    timeCodesControl: .init(dictionary: [:]),
    settingsControl: .init(dictionary: [:]),
    fullScreenControl: .init(dictionary: [:]),
    downloadControl: .init(dictionary: [:]),
    toastControl: .init(dictionary: [:]),
    headerControl: .init(dictionary: [:]),
    loadingControl: .init(dictionary: [:])
  )
  
  var size: CGSize
  var safeAreaInsets: EdgeInsets
  var onTapFullScreenControl: (Bool) -> Void
  var onTapSettingsControl: () -> Void
  var onTapHeaderGoback: () -> Void
  
  private var fileManager = PlayerFileManager()
  
  init(
    size: CGSize,
    safeAreaInsets: EdgeInsets,
    player: AVPlayer,
    menus: NSDictionary,
    controlsCallback: Controls,
    isLoading: Bool,
    title: String,
    playbackFinished: Bool,
    thumbnails: [UIImage],
    onTapFullScreenControl: @escaping (Bool) -> Void,
    doubleTapSeekValue: Int,
    suffixLabelDoubleTapSeek: String,
    isFullScreen: Bool,
    onTapSettingsControl: @escaping () -> Void,
    isActiveAutoPlay: Bool,
    isActiveLoop: Bool,
    videoGravity: AVLayerVideoGravity,
    sliderProgress: Double,
    lastDraggedProgress: Double,
    isPlaying: Bool?,
    controllersPropsData: HashableControllers?,
    downloadInProgress: Bool,
    downloadProgress: Float,
    onTapHeaderGoback: @escaping () -> Void
  ) {
      self.size = size
      self.safeAreaInsets = safeAreaInsets
      self.onTapFullScreenControl = onTapFullScreenControl
      self.onTapSettingsControl = onTapSettingsControl
      self.onTapHeaderGoback = onTapHeaderGoback
      _player = State(initialValue: player)
      _menus = State(initialValue: menus)
      _controlsCallback = State(initialValue: controlsCallback)
      _thumbnailsFrames = State(initialValue: thumbnails)
      _isFullScreen = State(wrappedValue: isFullScreen)
      _playbackObserver = ObservedObject(initialValue: PlaybackObserver())
      _isActiveAutoPlay = State(initialValue: isActiveAutoPlay)
      _isActiveLoop = State(initialValue: isActiveLoop)
      _videoGravity = State(wrappedValue: videoGravity)
      _isFinishedPlaying = State(initialValue: playbackFinished)
      _isPlaying = State(wrappedValue: isPlaying)
      _timeObserver = State(initialValue: nil)
      _title = State(initialValue: title)
      _isLoading = State(initialValue: isLoading)
      _doubleTapSeekValue = State(initialValue: doubleTapSeekValue)
      _suffixLabelDoubleTapSeek = State(initialValue: suffixLabelDoubleTapSeek)
      _controlsProps = State(initialValue: controllersPropsData)
      _downloadInProgress = State(initialValue: downloadInProgress)
      _downloadProgress = State(wrappedValue: downloadProgress)
  }
  
  var body: some View {
    VStack {
      let videoPlayerSize: CGSize = .init(width: size.width, height: size.height)
      
      ZStack {
            CustomVideoPlayer(player: player, videoGravity: videoGravity)
              .edgesIgnoringSafeArea(isFullScreen ? Edge.Set.all : [])
              .transition(.scale.combined(with: .opacity))
              .overlay(
                Rectangle()
                  .fill(Color.black.opacity(0.4))
                  .opacity(showPlayerControls || isDraggingSlider ? 1 : 0)
                  .animation(.easeInOut(duration: AnimationDuration.s035), value: isDraggingSlider)
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
                  advanceValue: doubleTapSeekValue,
                  suffixAdvanceValue: suffixLabelDoubleTapSeek
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
                    MenuControl()
                  }
                  .padding(.top, -StandardSizes.small8)
                  .opacity(showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap ? 1 : 0)
                  .animation(.easeInOut(duration: AnimationDuration.s035), value: showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap)
                }
                  .padding(.leading)
                  .padding(.trailing)
                  .padding(.bottom)
                  .overlay(
                    PlaybackControls()
                  )
              )
              
              .overlay(
                Group {
                  if isPresentToast {
                    Toast()
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
@available(iOS 14.0, *)
extension VideoPlayerView {
  @ViewBuilder
  func HeaderControls() -> some View {
      HStack {
          Button (action: {
              withAnimation(.easeInOut(duration: 0.35)) {
                  isFullScreen.toggle()
              }
            self.onTapFullScreenControl(isFullScreen)
          }) {
            CustomIcon(isFullScreen ? "xmark" : "arrow.up.left.and.arrow.down.right", color: controlsProps?.fullScreen.color)
          }
          Spacer()
      }
      .padding(.top, 12)
      .padding(.leading, 8)
    }

  @ViewBuilder
  func VideoSeekerThumbnailView() -> some View {
    let calculatedWidthThumbnailSizeByWidth = calculateSizeByWidth(StandardSizes.extraLarge200, VariantPercent.p40)
    let calculatedHeightThumbnailSizeByWidth = calculateSizeByWidth(StandardSizes.extraLarge100, VariantPercent.p40)
    
    let thumbSize: CGSize = .init(width: calculatedWidthThumbnailSizeByWidth, height: calculatedHeightThumbnailSizeByWidth)
  
    HStack {
      if let draggingImage {
        VStack {
          Image(uiImage: draggingImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: thumbSize.width, height: thumbSize.height)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(Color(uiColor: (controlsProps?.seekSlider.thumbnailBorderColor ?? .white)), lineWidth: 2)
            )
          Text(stringFromTimeInterval(interval: TimeInterval(truncating: (sliderProgress * duration) as NSNumber)))
            .font(.caption)
            .foregroundColor(Color(uiColor: controlsProps?.seekSlider.thumbnailTimeCodeColor ?? .white))
            .fontWeight(.semibold)
        }
      } else {
        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
          .fill(.black)
          .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
              .stroke(Color(uiColor: (controlsProps?.seekSlider.thumbnailBorderColor) ?? .white), lineWidth: 2)
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
            TimeCodes()
            HStack {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(uiColor: (controlsProps?.seekSlider.maximumTrackColor ?? .systemFill)))
                        .frame(width: size.width - seekerThumbImageSize.width)
                        .cornerRadius(CornerRadius.small)
                    
                    Rectangle()
                        .fill(Color(uiColor: (controlsProps?.seekSlider.seekableTintColor ?? .systemGray2)))
                        .frame(width: buffering * (size.width - seekerThumbImageSize.width))
                        .cornerRadius(CornerRadius.small)
                    
                    Rectangle()
                        .fill(Color(uiColor: (controlsProps?.seekSlider.minimumTrackColor ?? .systemBlue)))
                        .frame(width: calculateSliderWidth())
                        .cornerRadius(CornerRadius.small)
                    
                    HStack {}
                        .overlay(
                            Circle()
                                .fill(Color(uiColor: (controlsProps?.seekSlider.thumbImageColor ?? UIColor.white)))
                                .frame(width: seekerThumbImageSize.width, height: seekerThumbImageSize.height)
                                .frame(width: 40, height: 40)
                                .background(Color(uiColor: isSeeking ? .systemFill : .clear))
                                .cornerRadius(CornerRadius.infinity)
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
                .frame(height: isSeeking ? StandardSizes.seekerViewMaxHeight : StandardSizes.seekerViewMinHeight)
                .animation(.easeInOut(duration: AnimationDuration.s035), value: isSeeking)
            }
            .opacity(showPlayerControls || isSeeking || isSeekingByDoubleTap ? 1 : 0)
            .animation(.easeInOut(duration: AnimationDuration.s035), value: showPlayerControls || isSeekingByDoubleTap || isSeeking)
        }
    }
  
  @ViewBuilder
    func PlaybackControls() -> some View {
        let controllerSize = calculateSizeByWidth(StandardSizes.playbackControler, VariantPercent.p20)
        
        Rectangle()
            .fill(Color.black.opacity(0.5))
            .cornerRadius(.infinity, antialiased: true)
            .overlay(
                Group {
                    if isFinishedPlaying {
                        Button(action: {
                            resetPlaybackStatus()
                        }) {
                            Image(systemName: "gobackward")
                                .font(.system(size: controllerSize))
                                .foregroundColor(Color(uiColor: controlsProps?.playback.color ?? .white))
                        }
                        
                    } else {
                        if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                            CustomLoading(color: controlsProps?.loading.color)
                        } else {
                            CustomPlayPauseButton(
                                action: { isPlaying in
                                    onPlaybackManager(playing: isPlaying)
                                }, isPlaying: player.timeControlStatus != .paused,
                                frame: .init(origin: .zero, size: .init(width: controllerSize, height: controllerSize)),
                                color: controlsProps?.playback.color?.cgColor
                            )
                        }
                    }
                }
                
            )
            .frame(width: controllerSize * 2, height: controllerSize * 2)
            .opacity(showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap ? 1 : 0)
            .animation(.easeInOut(duration: AnimationDuration.s035), value: showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap)
    }
  
  @ViewBuilder
  func MenuControl() -> some View {
      CreateCircleMenuButton(menus: menus,
          CustomIcon("ellipsis", color: controlsProps?.settings.color)
      ) { label, value in
          controlsCallback.menuItemSelected(label, value)
      }
  }
  
  @ViewBuilder
  func DownloadControl() -> some View {
    let cached = PlayerFileManager().videoCached(title: title)
    let size = calculateSizeByWidth(StandardSizes.small14, VariantPercent.p20)
    let progressBarSize = calculateSizeByWidth(StandardSizes.medium24, VariantPercent.p10)
    
    Button (action: {
      showActionSheetFileManager = true
    }) {
      VStack {
        Image(systemName: "arrow.down")
          .foregroundColor(Color(uiColor: controlsProps?.download.color ?? .white))
          .font(.system(size: size))
        
        ZStack(alignment: .leading) {
          Rectangle()
            .fill(cached.fileExist ? Color(uiColor: controlsProps?.download.progressBarColor ?? .blue) : Color(uiColor: controlsProps?.download.progressBarColor ?? .white))
            .frame(width: progressBarSize, height: 2)
            .cornerRadius(CornerRadius.medium)
            
          
          Rectangle()
            .fill(Color(uiColor: controlsProps?.download.progressBarFillColor ?? .blue))
            .frame(width: CGFloat(downloadProgress / 100) * progressBarSize, height: 2)
            .cornerRadius(CornerRadius.medium)
        }
        
      }
      .padding(.trailing, 4)
    }
    .actionSheet(isPresented: $showActionSheetFileManager) {
        let buttons: [ActionSheet.Button]
        
        if !cached.fileExist {
          buttons = [
            .default(Text(controlsProps?.download.labelDownload ?? "Download")) {
              downloadInProgress = true
              notificationPostPlaybackInfo(userInfo: ["downloadInProgress": true])
              fileManager.downloadFile(from: urlOfCurrentPlayerItem(player: player)!, title: title, onProgress: { progress in
                self.downloadProgress = progress
                if downloadProgress >= 100 && downloadInProgress {
                  isPresentToast = true
                }
                notificationPostPlaybackInfo(userInfo: ["downloadProgress": downloadProgress])
              }, completion: { response, error in
                
                downloadInProgress = false
                notificationPostPlaybackInfo(userInfo: ["downloadInProgress": false])
                
              })
            },
            .cancel()
          ]
        } else {
            buttons = [
              .destructive(Text(controlsProps?.download.labelDelete ?? "Remove")) {
                  fileManager.deleteFile(title: title, completetion: { message, error in
                    self.downloadProgress = .zero
                  })
                },
              .cancel(Text(controlsProps?.download.labelCancel ?? "Cancel"))
            ]
        }
        
      return ActionSheet(
        title:
          Text(!cached.fileExist
               ? controlsProps?.download.messageDownload ?? "Do you want to download the video?"
               : controlsProps?.download.messageDelete ?? "This video has already been downloaded. Do you want to remove the video?"),
        buttons: buttons
      )
    }

  }
  
  @ViewBuilder
  func TimeCodes() -> some View {
    let sizeTimeCodes = calculateSizeByWidth(StandardSizes.small8, VariantPercent.p20)
    
    HStack(alignment: .center) {
      Spacer()
      Text(stringFromTimeInterval(interval: currentTime > duration ? duration : currentTime))
        .font(.system(size: sizeTimeCodes))
        .foregroundColor(Color(uiColor: (controlsProps?.timeCodes.currentTimeColor ?? .white)))
      
      Text("/")
        .font(.system(size: sizeTimeCodes))
        .foregroundColor(Color(uiColor: (controlsProps?.timeCodes.slashColor ?? .white)))
      
      Text(stringFromTimeInterval(interval: duration))
        .font(.system(size: sizeTimeCodes))
        .foregroundColor(Color(uiColor: (controlsProps?.timeCodes.durationColor ?? .white)))
    
    }
    .opacity(showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap ? 1 : 0)
    .animation(.easeInOut(duration: AnimationDuration.s035), value: showPlayerControls && !isDraggingSlider && !isSeekingByDoubleTap)
  }
  
  @ViewBuilder
  func Toast() -> some View {
    let size = calculateSizeByWidth(StandardSizes.small8, VariantPercent.p30)
    
    VStack {
      Spacer()
      Text(controlsProps?.toast.label ?? "Download successful")
        .font(.system(size: size))
        .padding()
        .foregroundColor(Color(uiColor: (controlsProps?.toast.labelColor ?? .white)))
        .background(Color(uiColor: (controlsProps?.toast.backgroundColor ?? .systemGray2)))
        .cornerRadius(CornerRadius.medium)
        .opacity(isPresentToast ? 1 : 0)
        .animation(.easeInOut(duration: AnimationDuration.s035))
        .onTapGesture {
          isPresentToast = false
          downloadInProgress = false
        }
        .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: AnimationDuration.s020)) {
              isPresentToast = false
              downloadInProgress = false
            }
          }
        }
        .padding(.bottom, UIScreen.main.bounds.height * 0.07)
      
    }
  }
}

// MARK: -- Private Functions
@available(iOS 14.0, *)
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
      return
    }
    
    if time.isNaN || currentItem.duration.seconds.isNaN {
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

      if !isSeeking  {
        if currentTime < duration {
          sliderProgress = calculatedProgress
          lastDraggedProgress = sliderProgress
          notificationPostPlaybackInfo(userInfo: ["sliderProgress": calculatedProgress, "lastDraggedProgress": calculatedProgress])
          
          isFinishedPlaying = false
          notificationPostPlaybackInfo(userInfo: ["playbackFinished": false])
        } else {
          onFinished()
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            if isActiveLoop {
              resetPlaybackStatus()
            }
          })
        }
      }
  }
  
  private func onPlaybackManager(playing: Bool) {
      if playing  {
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
      notificationPostPlaybackInfo(userInfo: ["isPlaying": playing])
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
  
  private func onFinished() {
    isFinishedPlaying = true
    notificationPostPlaybackInfo(userInfo: ["playbackFinished": true])
  }
  
  private func resetPlaybackStatus() {
    showPlayerControls = false
    isFinishedPlaying = false
    notificationPostPlaybackInfo(userInfo: ["playbackFinished": false])
    
    sliderProgress = .zero
    lastDraggedProgress = .zero
    currentTime = .zero
    player.seek(to: .zero, completionHandler: {completed in
      if completed && !isFinishedPlaying {
        player.play()
      }
    })
  }
  
  private func onTapGoback() {
    onTapHeaderGoback()
  }
}

// MARK: -- CustomView
@available(iOS 14.0, *)
struct CustomView : View {
    var player: AVPlayer
    var menus: NSDictionary
    var controlsCallback: Controls
    var isLoading: Bool
    var title: String
    var playbackFinished: Bool
    var videoGravity: AVLayerVideoGravity
    var thumbnails: [UIImage]
    var onTapFullScreenControl: (Bool) -> Void
    var tapToSeekValue: Int
    var suffixLabelDoubleTapSeek: String
    var isFullScreen: Bool
    var onTapSettingsControl: () -> Void
    var isActiveAutoPlay: Bool
    var isActiveLoop: Bool
    var sliderProgress: Double
    var lastDraggedProgress: Double
    var isPlaying: Bool?
    var controllersPropsData: HashableControllers?
    var downloadInProgress: Bool
    var downloadProgress: Float
    var onTapHeaderGoback: () -> Void
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeAreaInsets = $0.safeAreaInsets
            
            VideoPlayerView(
                size: size,
                safeAreaInsets: safeAreaInsets,
                player: player,
                menus: menus,
                controlsCallback: controlsCallback,
                isLoading: isLoading,
                title: title,
                playbackFinished: playbackFinished,
                thumbnails: thumbnails,
                onTapFullScreenControl: onTapFullScreenControl,
                doubleTapSeekValue: tapToSeekValue,
                suffixLabelDoubleTapSeek: suffixLabelDoubleTapSeek,
                isFullScreen: isFullScreen,
                onTapSettingsControl: onTapSettingsControl,
                isActiveAutoPlay: isActiveAutoPlay,
                isActiveLoop: isActiveLoop,
                videoGravity: videoGravity,
                sliderProgress: sliderProgress,
                lastDraggedProgress: lastDraggedProgress,
                isPlaying: isPlaying,
                controllersPropsData: controllersPropsData,
                downloadInProgress: downloadInProgress,
                downloadProgress: downloadProgress,
                onTapHeaderGoback: onTapHeaderGoback
            )
        }
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
