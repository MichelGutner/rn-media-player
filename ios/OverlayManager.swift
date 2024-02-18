//
//  OverlayLayoutManager.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 04/02/24.
//

import Foundation
import SwiftUI
import AVKit

@available(iOS 13.0, *)
struct OverlayManager : View {
  var safeAreaInsets: UIEdgeInsets
  var videoTitle: String
  var onTapFullScreen: () -> Void
  var isFullScreen: Bool
  var fullScreenConfig: NSDictionary?

  var onTapExit: () -> Void
  var onTapSettings: () -> Void
  var avPlayer : AVPlayer
  var onTapPlayPause: ([String: Any]) -> Void

  var onAppearOverlay: () -> Void
  var onDisappearOverlay: () -> Void

  @ObservedObject private var playbackObserver = PlayerObserver()
  @State private var playbackDuration: Double = 0
  @State private var isFinished: Bool = false
  @State private var status: PlayingStatus = .paused
  @State private var timeObserver: Any?
  
  @State private var playPauseimageName: String = "pause.fill"
  @State private var isTapped: Bool = false
  

  @State private var dynamicFontSize: CGFloat = calculateFrameSize(size14, variantPercent30)
  @State private var dynamicDurationTextSize: CGFloat = calculateFrameSize(size8, variantPercent20)
  @State private var dynamicTitleSize = calculateFrameSize(size14, variantPercent20)

  @State private var sliderValue = 0.0
  @GestureState private var isDraggingSlider: Bool = false
  @State private var progress: CGFloat = 0
  @State private var lastDraggedProgress: CGFloat = 0
  @State private var isSeeking: Bool = false
  
//  private var onSelectedOptionsItem: (Any) -> Void
  @State private var selectedItemOptions: String = ""
  
  
  var body: some View {
    ZStack {
      HeaderControlsView()
      MiddleControlsView()
      FooterControlsView()
      ModalManager(
        data: [["name": "x", "value": "x"]],
        title: "Configurações",
        onAppear: {},
        onDisappear: {},
        completionHandler: {},
        children: {
          ModalOptionsView([["name": "x", "value": "x"]])
        },
        isOpened: .constant(true)
      )
    }
    .onAppear {
      periodicTimeObserver()
      onAppearOverlay()
      updateImage()
      NotificationCenter.default.addObserver(
        playbackObserver,
        selector: #selector(PlayerObserver.itemDidFinishPlaying(_:)),
        name: .AVPlayerItemDidPlayToEndTime,
        object: avPlayer.currentItem
      )
      
      NotificationCenter.default.addObserver(
        forName: UIApplication.willChangeStatusBarOrientationNotification,
        object: nil,
        queue: .main
      ) { _ in
        updateDynamicSize()
        updateImage()
      }
    }
    .onReceive(playbackObserver.$isFinishedPlaying) { isFinishedPlaying in
      if isFinishedPlaying {
        isFinished = true
        playPauseimageName = "gobackward"
        status = .finished
      }
    }
  }
  
  @ViewBuilder
  func HeaderControlsView() -> some View {
    VStack {
      HStack {
        Button (action: {
          onTapExit()
        }) {
          Image(systemName: "arrow.left")
            .font(.system(size: dynamicFontSize))
            .foregroundColor(.white)
        }
        .padding(.leading, 8)
        Spacer()
        Text(videoTitle).font(.system(size: dynamicTitleSize)).foregroundColor(.white)
        Spacer()
      }
      Spacer()
    }
    .opacity(isSeeking ? 0 : 1)
    .animation(.easeInOut(duration: 0.2), value: isSeeking)
  }
  
  @ViewBuilder
  func MiddleControlsView() -> some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        Button(action: {
          isTapped.toggle()
          onPlaybackManager(completionHandler: { completed in
            if completed {
              updateImage()
            }
          })
        }) {
          Image(systemName: playPauseimageName)
            .foregroundColor(.white)
            .font(.system(size: dynamicFontSize))
        }
        .padding(size16)
        .background(Color(.black).opacity(0.2))
        .cornerRadius(.infinity)
        Spacer()
      }
      .fixedSize(horizontal: true, vertical: true)
      Spacer()
    }
    .opacity(isSeeking ? 0 : 1)
    .animation(.easeInOut(duration: 0.2), value: isSeeking)
  }
  
  @ViewBuilder
  func FooterControlsView() -> some View {
      VStack {
        Spacer()
        HStack {
          VideoSeekerView()
        }
        HStack {
          VideoTimeLineView()
          Spacer()
          
          SettingsView()
          FullScreenView()
        }
        .opacity(isSeeking ? 0.001 : 1)
        .animation(.easeInOut(duration: 0.2), value: isSeeking)
      }
      .onReceive(playbackObserver.$playbackDuration) { duration in
        if duration != 0.0 {
          playbackDuration = duration
        }
        if  avPlayer.currentItem?.duration.seconds != 0.0 {
          playbackDuration = (avPlayer.currentItem?.duration.seconds)!
          progress = avPlayer.currentTime().seconds / (avPlayer.currentItem?.duration.seconds)!
          lastDraggedProgress = progress
        }
      }
  }
  
  
  // Components
  @ViewBuilder
  func SettingsView() -> some View {
    Button(action: {
        withAnimation(.linear(duration: 0.2)) {
            onTapSettings()
        }
    }) {
        Image(systemName: "gear")
            .font(.system(size: dynamicFontSize))
            .foregroundColor(.white)
            .padding(8)
    }
    .fixedSize(horizontal: true, vertical: true)
  }
  
  @ViewBuilder
  func FullScreenView() -> some View {
    let color = fullScreenConfig?["color"] as? String
    let isHidden = fullScreenConfig?["hidden"] as? Bool
    
    Button (action: {
      onTapFullScreen()
    }) {
      Image(
        systemName:
          isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
      )
      .padding(8)
    }
    .font(.system(size: dynamicFontSize))
    .foregroundColor(Color(transformStringIntoUIColor(color: color)))
    .rotationEffect(.init(degrees: 90))
    .opacity(isHidden ?? false ? 0 : 1)
  }
  
  @ViewBuilder
  func VideoSeekerView() -> some View {
      ZStack(alignment: .leading) {
        let safeAreaWidth = UIScreen.main.bounds.inset(by: safeAreaInsets).width
        
        Rectangle()
          .fill(.gray)
          .frame(width: safeAreaWidth)
          .cornerRadius(8)
        
        Rectangle()
          .fill(.red)
          .frame(width: max(safeAreaWidth * progress, 0))
          .cornerRadius(8)
        HStack {}
          .overlay(
            Circle()
              .fill(.red)
              .frame(width: 15, height: 15)
              .frame(width: 50, height: 50)
              .contentShape(Rectangle())
              .offset(x: safeAreaWidth * progress)
              .gesture(
                DragGesture()
                  .updating($isDraggingSlider, body: { _, out, _ in
                    out = true
                  })
                  .onChanged({ value in
                    let translationX: CGFloat = value.translation.width
                    let calculatedProgress = (translationX / safeAreaWidth) + lastDraggedProgress
                    progress = max(min(calculatedProgress, 1), 0)
                    isSeeking = true
                  })
                  .onEnded({ value in
                    lastDraggedProgress = progress
                    
                    if let currentItem = avPlayer.currentItem {
                      let duration = currentItem.duration.seconds
                      let targetTime = duration * progress
                      let targetCMTime = CMTime(seconds: targetTime, preferredTimescale: Int32(NSEC_PER_SEC))
                              
                      avPlayer.seek(to: targetCMTime)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                      isSeeking = false
                    })
                  })
              )
          )
      }
      .frame(height: 3)
    }
  
  @ViewBuilder
  func VideoTimeLineView() -> some View {
    Text("\(stringFromTimeInterval(interval: avPlayer.currentTime().seconds)) / \(stringFromTimeInterval(interval: playbackDuration))")
      .foregroundColor(.white)
      .font(.system(size: dynamicDurationTextSize))
      .padding(.leading, 8)
  }
  
  @ViewBuilder
  func ModalOptionsView(_ data: [[String: String]]) -> some View {
    ScrollView(showsIndicators: false) {
      VStack {
        ForEach(data, id: \.self) { item in
          Button(action: {
            hidden()
            if let floatValue = Float(item["value"] ?? "")  {
//              onSelected(floatValue)
            } else {
//              onSelected(item["value"] as Any)
            }
            self.selectedItemOptions = item["name"]!
            
          }) {
            
            HStack {
              ZStack {
                Circle().stroke(Color.white, lineWidth: 1).frame(width: 12, height: 12)
                
                if self.selectedItemOptions == item["name"] {
                  Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                }
              }
              .fixedSize(horizontal: false, vertical: true)
              
              Text("\(item["name"] ?? "")").foregroundColor(.white)
            }
            .frame(width: UIScreen.main.bounds.width / 2, alignment: .leading)
          }
          .disabled(selectedItemOptions == item["name"])
        }
      }
    }
    .fixedSize(horizontal: true, vertical: true)
  }
  
  // functions
  private func periodicTimeObserver() {
    timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main) { [self] time in
        if let currentPlayerItem = avPlayer.currentItem {
          let duration = currentPlayerItem.duration.seconds
          let currentProgress = avPlayer.currentTime().seconds
          progress = currentProgress / duration
          playbackDuration = duration
        }
      }
  }
  
  private func updateDynamicSize() {
    dynamicFontSize = calculateFrameSize(size14, variantPercent30)
    dynamicDurationTextSize = calculateFrameSize(size10, variantPercent20)
    dynamicTitleSize = calculateFrameSize(size14, variantPercent20)
  }
  
  private func PlayingStatusManager(_ status: PlayingStatus) -> String {
    switch (status) {
    case .playing:
      return "isPlaying"
    case .paused:
      return "isPaused"
    case .finished:
      return "isFinished"
    }
  }
  
  private func onPlaybackManager(completionHandler: @escaping (Bool) -> Void) {
    if isFinished {
      status = .finished
      avPlayer.currentItem?.seek(to: CMTime(value: CMTimeValue(0), timescale: 1), completionHandler: completionHandler)
    } else {
      if avPlayer.timeControlStatus == .paused  {
        avPlayer.play()
        status = .playing
      } else {
        avPlayer.pause()
        status = .paused
      }
    }
    updateImage()
    onTapPlayPause(["status": PlayingStatusManager(status)])
  }
  
  private func updateImage() {
    guard let currentIem = avPlayer.currentItem else { return }
    if avPlayer.currentTime().seconds >= (currentIem.duration.seconds - 3) {
      isFinished = true
      playPauseimageName = "gobackward"
    } else {
      avPlayer.timeControlStatus == .paused ? (playPauseimageName = "play.fill") : (playPauseimageName = "pause.fill")
      isFinished = false
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
