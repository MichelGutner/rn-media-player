//
//  Overlay.swift
//  Pods
//
//  Created by Michel Gutner on 24/10/24.
//

import SwiftUI
import AVKit
import Combine

public enum MediaPlayerControlButtonType {
  case playPause
  case fullscreen
  case optionsMenu
  case seekGestureForward
  case seekGestureBackward
}


public enum MediaPlayerControlActionState : Int {
  case fullscreenActive = 0
  case fullscreenInactive = 1
  case seekGestureForward = 2
  case seekGestureBackward = 3
}

@available(iOS 14.0, *)
public protocol MediaPlayerControlsViewDelegate : AnyObject {
  func controlDidTap(_ control: MediaPlayerControlsView, controlType: MediaPlayerControlButtonType, didChangeControlEvent event: Any?)
  func sliderDidChange(_ control: MediaPlayerControlsView, didChangeProgressFrom fromValue: Double, didChangeProgressTo toValue: Double)
}

@available(iOS 14.0, *)
public struct MediaPlayerControlsView : View {
  @ObservedObject private var screenState = SharedScreenState.instance
  @ObservedObject private var playback = PlaybackManager.shared
  @ObservedObject private var metadataIdentifier = SharedMetadataIdentifier.instance
  @ObservedObject private var configs = RCTConfigManager.shared
  
  var mediaSource: PlayerSource
  @State private var isTappedRight: Bool = false
  @State private var isTappedLeft: Bool = false
  
  public weak var delegate: MediaPlayerControlsViewDelegate?
  @State private var isDraggingSlider: Bool = false
  
  @State private var isControlsVisible: Bool = true
  @State private var timeoutWorkItem: DispatchWorkItem?
  @State private var isSeeking: Bool = false
  @State private var cancellables = Set<AnyCancellable>()
  
  public var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(
          colors: [
            Color.black.opacity(0.5),
            Color.black.opacity(0.2),
            Color.black.opacity(0.5)
          ]
        ),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      .opacity(isControlsVisible ? 1 : 0)
    }
    .overlay(
      DoubleTapSeekControlView()
    )
    .overlay(
      VStack {
        HeaderControlsView()
          .opacity(isControlsVisible ? 1 : 0)
        Spacer()
        BottomControlsView()
          .opacity(isControlsVisible || isSeeking || isDraggingSlider ? 1 : 0)
      }
        .padding(16)
        .background(Color.clear)
    )
    .overlay(
      ZStack(alignment: .center) {
        MiddleControlsView()
          .opacity(isControlsVisible ? 1 : 0)
      }
    )
    .overlay(
      ZStack(alignment: .center) {
        CustomLoading(color: .white)
      }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .opacity(playback.isReady ? 0 : 1)
        .animation(.easeInOut(duration: 0.35), value: playback.isReady)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(Rectangle())
    .onTapGesture {
      if playback.isReady {
        toggleControls()
        if isControlsVisible {
          scheduleHideControls()
        }
      }
    }
    .onAppear {
      playback.$isPlaying.sink { [self] isPlaying in
        if isPlaying, !isSeeking, isControlsVisible {
          scheduleHideControls()
        }
      }.store(in: &cancellables)
    }
  }
  
  @ViewBuilder
  func DoubleTapSeekControlView() -> some View {
    HStack(spacing: 55) {
      DoubleTapSeek(
        value: configs.data.doubleTapToSeek?.value,
        suffixLabel: configs.data.doubleTapToSeek?.suffixLabel,
        isTapped: $isTappedLeft,
        onSeek: { value, completed in
          isDraggingSlider = true
          isControlsVisible = false
          self.delegate?.controlDidTap(self, controlType: .seekGestureBackward, didChangeControlEvent: value)
          if completed {
            isDraggingSlider = false
          }
        }
      )
      
      DoubleTapSeek(
        value: configs.data.doubleTapToSeek?.value,
        suffixLabel: configs.data.doubleTapToSeek?.suffixLabel,
        isTapped: $isTappedRight,
        isForward: true,
        onSeek: { value, completed in
          isDraggingSlider = true
          isControlsVisible = false
          self.delegate?.controlDidTap(self, controlType: .seekGestureForward, didChangeControlEvent: value)
          if completed {
            isDraggingSlider = false
          }
        }
      )
    }
  }
  
  @ViewBuilder
  func HeaderControlsView() -> some View {
    HStack(alignment: .top) {
      Group {
        // Header title
        let title = metadataIdentifier.title
        
          if #available(iOS 15.0, *) {
            Text(title)
              .font(.system(size: 14))
              .foregroundStyle(.white)
          } else {
            Text(title)
              .font(.system(size: 14))
              .foregroundColor(.white)
          }
      }
      Spacer()
      
      // Router Picker -- AirPlay
      RoutePickerView()
        .frame(width: 25, height: 25)
    }
    .offset(y: isControlsVisible ? 0 : -5)
    .opacity(!isDraggingSlider ? 1 : 0)
  }
  
  @ViewBuilder
  func MiddleControlsView() -> some View {
    PlayPauseButtonRepresentable(
      action: {
        delegate?.controlDidTap(self, controlType: .playPause, didChangeControlEvent: nil)
        scheduleHideControls()
      },
      color: UIColor.white.cgColor,
      frame: .init(origin: .init(x: 0, y: 0), size: .init(width: 35, height: 35))
    )
    .frame(width: 70, height: 70)
    .opacity(!isDraggingSlider ? 1 : 0)
  }
  
  @ViewBuilder
  func BottomControlsView() -> some View {
    VStack {
      HStack {
        Spacer()
        CustomMenus(onSelect: { key, value in
          delegate?.controlDidTap(self, controlType: .optionsMenu, didChangeControlEvent: (key, value))
        })

        Button(action: {
          delegate?.controlDidTap(self, controlType: .fullscreen, didChangeControlEvent: !screenState.isFullScreen)
          scheduleHideControls()
        }, label: {
          Image(systemName: screenState.isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
            .rotationEffect(.degrees(90))
            .foregroundColor(.white)
            .font(.system(size: 18))
        })
        .padding(12)
        .clipShape(Circle())
      }
      .opacity(!isDraggingSlider ? 1 : 0)
      
      InteractiveMediaSeekSlider(
        player: mediaSource.player,
        isSeeking: $isSeeking,
        onSeekBegan: {
          isDraggingSlider = true
          cancelTimeoutWorkItem()
        },
        onSeekEnded: { startProgress, endProgress in
          isDraggingSlider = false
          scheduleHideControls()
          self.delegate?.sliderDidChange(self, didChangeProgressFrom: startProgress, didChangeProgressTo: endProgress)
        })
    }
    .offset(y: isControlsVisible || isDraggingSlider || isSeeking ? 0 : 5)
    .animation(.easeInOut, value: isControlsVisible)
  }
  
  fileprivate func toggleControls() {
    withAnimation(.easeInOut(duration: 0.25), {
      isControlsVisible.toggle()
    })
  }
  
  fileprivate func scheduleHideControls() {
    DispatchQueue.main.async { [self] in
      if let timeoutWorkItem {
        timeoutWorkItem.cancel()
      }
      
      if (playback.isPlaying) {
        self.timeoutWorkItem = .init(block: { [self] in
          withAnimation(.easeInOut(duration: 0.35), {
            isControlsVisible = false
          })
        })
        
        
        if let timeoutWorkItem {
          DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: timeoutWorkItem)
        }
      }
    }
  }
  
  fileprivate func cancelTimeoutWorkItem() {
    DispatchQueue.main.async { [self] in
      if let timeoutWorkItem {
        timeoutWorkItem.cancel()
      }
    }
  }
}
