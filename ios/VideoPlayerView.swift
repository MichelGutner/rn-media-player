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
    var safeAreaInsets: UIEdgeInsets
    var player: AVPlayer
    @State var options: NSDictionary? = [:]
    var controls: PlayerControls
    var thumbNailsProps: NSDictionary? = [:]
    var enterInFullScreenWhenDeviceRotated = false
    var videoGravity: AVLayerVideoGravity
    var UIControlsProps: HashableControllers? = .init(
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
    var tapToSeek: NSDictionary? = [:]
    
    @State private var isFullScreen: Bool = false
    @State private var controlsVisible: Bool = true
    @State private var isReadyToPlay = false
    @GestureState private var isDraggedSeekSlider: Bool = false
    @State private var isSeeking: Bool = false
    @State private var isSeekingByDoubleTap: Bool = false
    @State private var isFinishedPlaying: Bool = false
    
    @State private var timeoutWorkItem: DispatchWorkItem?
    @State private var periodicTimeObserver: Any? = nil
    @State private var interval = CMTime(value: 1, timescale: 2)
    
    @State private var sliderProgress: CGFloat = 0.0
    @State private var bufferingProgress: CGFloat = 0.0
    @State private var lastDraggedProgresss: CGFloat = 0.0
    
    @State private var tolerance = CMTime(seconds: 0.1, preferredTimescale: Int32(NSEC_PER_SEC))
    @State private var seekerThumbImageSize: CGSize = .init(width: 12, height: 12)
    @State private var offsetY: CGFloat = 0.0
    
    @State private var thumbnailsFrames: [UIImage] = []
    @State private var draggingImage: UIImage?
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                CustomVideoPlayer(player: player, videoGravity: videoGravity)
                    .ignoresSafeArea(edges: isFullScreen ? Edge.Set.all : [])
                    .overlay(
                        Rectangle()
                            .fill(Color.black.opacity(0.4))
                            .opacity(controlsVisible || controlsVisible ? 1 : 0)
                            .animation(.easeInOut(duration: 0.35), value: isDraggedSeekSlider || controlsVisible)
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
                            //                        advanceValue: doubleTapSeekValue,
                            //                        suffixAdvanceValue: suffixLabelDoubleTapSeek
                            advanceValue: tapToSeek?["value"] as? Int ?? 15,
                            suffixAdvanceValue: tapToSeek?["suffixLabel"] as? String ?? "seconds"
                        )
                    )
                    .onAppear {
                        if let thumbNailsEnabled = thumbNailsProps?["enableGenerate"] as? Bool {
                            if let thumbnailsUrl = thumbNailsProps?["url"] as? String, thumbNailsEnabled {
                                generatingThumbnailsFrames(thumbnailsUrl)
                            }
                        }
                        
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
                        periodicTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                            updatePlayerTime(time.seconds)
                        }
                    }
                    .onReceive(playbackObserver.$deviceOrientation, perform: { isPortrait in
                        if (enterInFullScreenWhenDeviceRotated) {
                            if (isFullScreen && isPortrait) {
                                isFullScreen = true
                            } else {
                                isFullScreen = !isPortrait
                            }
                        }
                    })
                    .onReceive(playbackObserver.$isFinished, perform: { isFinished in
                        isFinishedPlaying = isFinished
                        timeoutWorkItem?.cancel()
                    })
                    .onTapGesture {
                        withAnimation {
                            toggleControls()
                        }
                    }
                    .overlay(
                        ViewControllers(geometry: geometry)
                            .onTapGesture {
                                withAnimation{
                                    toggleControls()
                                }
                            }
                    )
                    .overlay (
                        PlaybackControls()
                    )
            }
        }
    }
    
    @ViewBuilder
    func ViewControllers(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                Button(action: {
                    controlsVisible = false
                    controls.toggleFullScreen()
                    timeoutWorkItem?.cancel()
                    
                    if (isFullScreen) {
                        isFullScreen = false
                    } else {
                        isFullScreen = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        withAnimation {
                            controlsVisible = true
                        }
                    })
                    
                    if (player.timeControlStatus == .playing) {
                        scheduleHideControls()
                    }
                    
                }, label: {
                    CustomIcon(isFullScreen ? "xmark" : "arrow.up.left.and.arrow.down.right", color: UIControlsProps?.fullScreen.color)
                })
                Spacer()
            }
            .padding(.top, 12)
            .opacity(controlsVisible && !isDraggedSeekSlider && !isSeekingByDoubleTap ? 1 : 0)
            Spacer()
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    if thumbnailsFrames.count > 0 {
                        VideoSeekerThumbnailView(geometry: geometry)
                    }
                    Spacer()
                }
                HStack{
                    SeekSlider()
                    TimeCodes()
                        .fixedSize()
                    CreateCircleMenuButton (
                        action: {
                        },
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14.0, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .opacity(controlsVisible && !isDraggedSeekSlider && !isSeekingByDoubleTap ? 1 : 0)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    func CreateCircleButton(action: @escaping () -> Void,_ overlay: some View) -> some View {
        Button(action: action) {
            Circle()
                .fill(.gray.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(overlay)
        }
    }
    
    func CreateCircleMenuButton(action: @escaping () -> Void, _ overlay: some View) -> some View {
        var transformedNSDictionaryIntoSwiftDictionary: [(key: String, values: [NSDictionary])] = []
        
        if let options = options {
            transformedNSDictionaryIntoSwiftDictionary = options.compactMap { (key, value) -> (key: String, values: [NSDictionary])? in
                if let key = key as? String, let values = value as? [NSDictionary] {
                    return (key: key, values: values)
                }
                
                return nil
            }
        }
        
        return Menu {
            ForEach(transformedNSDictionaryIntoSwiftDictionary, id: \.key) { option in
                Menu(option.key) {
                    ForEach(option.values, id: \.self) { item in
                        Button(action: {
                            let name = item["name"] as! String
                            let value = item["value"] as Any
                            controls.optionSelected(option.key, value)
                        }) {
                            if let name = item["name"] as? String {
                                Label(name, systemImage: "chevron.right")
                            }
                        }
                    }
                }
                
            }
        } label: {
            Circle()
                .fill(Color.black.opacity(0.4))
                .frame(width: 40, height: 40)
                .overlay(overlay)
        }
    }
    
    @ViewBuilder
    func SeekSlider() -> some View {
        ZStack(alignment: .leading) {
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color(uiColor: (UIControlsProps?.seekSlider.maximumTrackColor ?? .systemFill)))
                    .frame(width: geometry.size.width - seekerThumbImageSize.width)
                    .cornerRadius(12)
                    .border(Color(uiColor: (UIControlsProps?.seekSlider.maximumTrackColor ?? .systemFill)), width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                    .shadow(radius: 10)
                
                Rectangle()
                    .fill(Color(uiColor: (UIControlsProps?.seekSlider.seekableTintColor ?? .systemGray2)))
                    .frame(width: bufferingProgress * (geometry.size.width - seekerThumbImageSize.width))
                    .cornerRadius(12)
                
                Rectangle()
                    .fill(Color(uiColor: (UIControlsProps?.seekSlider.minimumTrackColor ?? .blue)))
                    .frame(width: sliderProgress * (geometry.size.width - seekerThumbImageSize.width))
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
                            .offset(x: sliderProgress * (geometry.size.width - seekerThumbImageSize.width), y: geometry.size.height / 2)
                            .gesture(
                                DragGesture()
                                    .updating($isDraggedSeekSlider, body: {_, out, _ in
                                        out = true
                                    })
                                    .onChanged({ value in
                                        let translation = value.translation.width / geometry.size.width
                                        sliderProgress = max(min(translation + lastDraggedProgresss, 1), 0)
                                        isSeeking = true
                                        timeoutWorkItem?.cancel()
                                        
                                        let dragIndex = Int(sliderProgress / 0.01)
                                        if thumbnailsFrames.indices.contains(dragIndex) {
                                            draggingImage = thumbnailsFrames[dragIndex]
                                        }
                                    })
                                    .onEnded({ value in
                                        lastDraggedProgresss = sliderProgress
                                        guard let playerItem = player.currentItem else { return }
                                        
                                        let targetTime =  playerItem.duration.seconds * sliderProgress
                                        
                                        let targetCMTime = CMTime(seconds: targetTime, preferredTimescale: Int32(NSEC_PER_SEC))
                                        
                                        player.seek(to: targetCMTime, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: { completed in
                                            if (completed) {
                                                isSeeking = false
                                            }
                                        })
                                        if  player.timeControlStatus == .playing {
                                            scheduleHideControls()
                                        }
                                    })
                            )
                    )
            }
            .frame(height: isSeeking ? 8 : 4)
            .animation(.easeInOut(duration: 0.35), value: isSeeking)
            .opacity(isSeeking || controlsVisible || isSeekingByDoubleTap ? 1 : 0)
            .animation(.easeInOut(duration: 0.35), value: isSeeking || controlsVisible || isSeekingByDoubleTap)
        }
    }
    
    @ViewBuilder
    func VideoSeekerThumbnailView(geometry: GeometryProxy) -> some View {
        let calculatedWidthThumbnailSizeByWidth = calculateSizeByWidth(200, 0.4)
        let calculatedHeightThumbnailSizeByWidth = calculateSizeByWidth(100, 0.4)
        
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
                                .stroke(Color(uiColor: (UIControlsProps?.seekSlider.thumbnailBorderColor ?? .white)), lineWidth: 2)
                        )
                    Text(stringFromTimeInterval(interval: TimeInterval(truncating: (sliderProgress * (player.currentItem?.duration.seconds)!) as NSNumber)))
                        .font(.caption)
                        .foregroundColor(Color(uiColor: UIControlsProps?.seekSlider.thumbnailTimeCodeColor ?? .white))
                        .fontWeight(.semibold)
                }
            } else {
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                            .stroke(Color(uiColor: (UIControlsProps?.seekSlider.thumbnailBorderColor) ?? .white), lineWidth: 2)
                    )
            }
        }
        .frame(width: thumbSize.width, height: thumbSize.height)
        .opacity(isDraggedSeekSlider ? 1 : 0)
        .offset(x: sliderProgress * (geometry.size.width - thumbSize.width))
        .animation(.easeInOut(duration: 0.35), value: isDraggedSeekSlider)
    }
    
    @ViewBuilder
    func PlaybackControls() -> some View {
        Circle()
            .fill(.black.opacity(0.40))
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
                                action: { _ in
                                    onPlayPause()
                                },
                                isPlaying: player.timeControlStatus == .playing,
                                frame: .init(origin: .zero, size: .init(width: 30, height: 30)),
                                color: UIControlsProps?.playback.color?.cgColor
                            )
                        }
                    }
                }
                
            )
            .frame(width: 60, height: 60)
            .opacity(controlsVisible && !isDraggedSeekSlider && !isSeekingByDoubleTap ? 1 : 0)
            .animation(.easeInOut(duration: 0.35), value: controlsVisible && !isDraggedSeekSlider && !isSeekingByDoubleTap)
    }
    
    @ViewBuilder
    func TimeCodes() -> some View {
        let sizeTimeCodes = calculateSizeByWidth(10, 0.2)
        
        HStack() {
            Spacer()
            //      Text(stringFromTimeInterval(interval: currentTime > duration ? duration : currentTime))
            //        .font(.system(size: sizeTimeCodes))
            //        .foregroundColor(Color(uiColor: (controlsProps?.timeCodes.currentTimeColor ?? .white)))
            //
            //      Text("/")
            //        .font(.system(size: sizeTimeCodes))
            //        .foregroundColor(Color(uiColor: (controlsProps?.timeCodes.slashColor ?? .white)))
            
            Text(stringFromTimeInterval(interval: player.currentItem?.duration.seconds ?? 0))
                .font(.system(size: sizeTimeCodes))
                .foregroundColor(Color(uiColor: (UIControlsProps?.timeCodes.durationColor ?? .white)))
            
        }
        .opacity(controlsVisible || isSeeking ? 1 : 0)
        .animation(.easeInOut(duration: 0.35), value: controlsVisible)
    }
    
    private func onPlayPause() {
        if (player.timeControlStatus == .playing) {
            player.pause()
            
            if let timeoutWorkItem {
                timeoutWorkItem.cancel()
            }
        } else {
            player.play()
            
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
    
    private func updatePlayerTime(_ time: CGFloat) {
        guard let currentItem = player.currentItem else {
            return
        }
        
        if time.isNaN || currentItem.duration.seconds.isNaN {
            return
        }
        
        //      currentTime = time
        let duration = currentItem.duration.seconds
        let calculatedProgress = time / duration
        
        let loadedTimeRanges = currentItem.loadedTimeRanges
        if let firstTimeRange = loadedTimeRanges.first?.timeRangeValue {
            let bufferedStart = CMTimeGetSeconds(firstTimeRange.start)
            let bufferedDuration = CMTimeGetSeconds(firstTimeRange.duration)
            let bufferedEnd = CMTimeGetSeconds(firstTimeRange.end)
            bufferingProgress = (bufferedStart + bufferedDuration) / duration
        }
        
        if !isSeeking  {
            if time < duration {
                sliderProgress = calculatedProgress
                lastDraggedProgresss = sliderProgress
                isFinishedPlaying = false
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
                generator.maximumSize = .init(width: 250, height: 250)
                
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
