//
//  Overlay.swift
//  Pods
//
//  Created by Michel Gutner on 24/10/24.
//

import SwiftUI
import AVKit
import Combine

@available(iOS 14.0, *)
public protocol MediaPlayerControlsViewDelegate : AnyObject {
  func controlDidTap(_ control: MediaPlayerControlsView, controlType: MediaPlayerControlButtonType)
  func controlDidTap(_ control: MediaPlayerControlsView, controlType: MediaPlayerControlButtonType, seekGestureValue value: Int)
  func controlDidTap(_ control: MediaPlayerControlsView, controlType: MediaPlayerControlButtonType, optionMenuSelected option: ((String, Any)))
  func sliderDidChange(_ control: MediaPlayerControlsView, didChangeProgressFrom fromValue: Double, didChangeProgressTo toValue: Double)
}

@available(iOS 14.0, *)
public struct MediaPlayerControlsView : View {
  @ObservedObject private var playbackState = PlaybackStateObservable.shared
  @ObservedObject private var screenState = ScreenStateObservable.shared
  
  @ObservedObject var mediaSession = MediaSessionManager()
  @State private var isTapped: Bool = false
  @State private var isTappedLeft: Bool = false
  
  @State private var currentTime: Double = 0.0
  @State private var duration: Double = 0.0
  
  @State private var bufferingProgress: CGFloat = 0.0
  @State private var lastProgress: Double = 0.0
  
  public weak var delegate: MediaPlayerControlsViewDelegate?
  
  @State private var seekerThumbImageSize: CGSize = .init(width: 12, height: 12)
  @State private var thumbnailsUIImageFrames: [UIImage] = []
  @State private var draggingImage: UIImage? = nil
  @State private var showThumbnails: Bool = false
  
  @State private var startSliderProgressFrom = 0.0
  
  @State private var isControlsVisible: Bool = true
  @State private var timeoutWorkItem: DispatchWorkItem?
  @State private var isSeeking: Bool = false
  @State private var cancellables = Set<AnyCancellable>()
  
  public var body: some View {
    ZStack{
      CustomLoading(color: .white)
        .opacity(playbackState.isReady ? 0 : 1)
      
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        
        // DoubleTap Seek ---
        HStack(spacing: StandardSizes.large55) {
          DoubleTapSeek(
            isTapped: $isTappedLeft,
            onSeek: { value, completed in
              cancelTimeoutWorkItem()
              delegate?.controlDidTap(self, controlType: .seekGestureBackward, seekGestureValue: value)
              
              if completed {
                scheduleHideControls()
              }
            }
          )
          DoubleTapSeek(
            isTapped: $isTapped,
            isForward: true,
            onSeek: { value, completed in
              cancelTimeoutWorkItem()
              delegate?.controlDidTap(self, controlType: .seekGestureForward, seekGestureValue: value)
              
              if completed {
                scheduleHideControls()
              }
            }
          )
        }
        
      }
      .opacity(isControlsVisible ? 1 : 0.0001)
      .animation(.easeInOut(duration: 0.35), value: isControlsVisible)
      .overlay(
        ZStack(alignment: .center) {
          PlayPauseButtonRepresentable(action: {
            delegate?.controlDidTap(self, controlType: .playPause)
            scheduleHideControls()
          }, color: UIColor.white.cgColor, frame: .init(origin: .init(x: 0, y: 0), size: .init(width: 35, height: 35)))
          .frame(width: 70, height: 70)
          .opacity(!isSeeking ? 1 : 0)
          VStack {
            HStack(alignment: .top) {
              Group {
                // Header title
                if let title = mediaSession.currentItemtitle {
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
              }
              Spacer()
              
              // Router Picker -- AirPlay
              RoutePickerView()
                .frame(width: 35, height: 35)
            }
            .offset(y: isControlsVisible ? 0 : -5)
            .opacity(!isSeeking ? 1 : 0)
            
            Spacer()
            
            VStack {
              Spacer()
              HStack {
                Spacer()
                CustomMenus(onSelect: { key, value in
                  delegate?.controlDidTap(self, controlType: .optionsMenu, optionMenuSelected: (key, value))
                })
                .background(Color.clear)
                .clipShape(Circle())
                
                Button(action: {
                  delegate?.controlDidTap(self, controlType: .fullscreen)
                  scheduleHideControls()
                }, label: {
                  Image(systemName: screenState.isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .rotationEffect(.degrees(90))
                    .padding(EdgeInsets.init(top: 12, leading: 12, bottom: 4, trailing: 12))
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                })
                .background(Color.clear)
                .clipShape(Circle())
              }
              .opacity(!isSeeking ? 1 : 0)
              
              InteractiveMediaSeekSlider(
                isSeeking: $isSeeking,
                onSeekBegan: {
                  cancelTimeoutWorkItem()
                },
                onSeekEnded: { startProgress, endProgress in
                  scheduleHideControls()
                  self.delegate?.sliderDidChange(self, didChangeProgressFrom: startProgress, didChangeProgressTo: endProgress)
                })
            }
            .offset(y: isControlsVisible ? 0 : 5)
            
            .animation(.easeInOut, value: isControlsVisible)
          }
          .padding(16)
          .background(Color.clear)
        }
          .opacity(isControlsVisible ? 1 : 0)
      )
      .onTapGesture {
        if playbackState.isReady {
          toggleControls()
          if isControlsVisible {
            scheduleHideControls()
          }
        }
      }
      .opacity(playbackState.isReady ? 1 : 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      playbackState.$isPlaying.sink { [self] isPlaying in
        if isPlaying, !isSeeking, isControlsVisible {
          scheduleHideControls()
        }
      }.store(in: &cancellables)
    }
  }
  
  func toggleControls() {
    withAnimation(.easeInOut(duration: 0.4), {
      isControlsVisible.toggle()
    })
  }
  
  func scheduleHideControls() {
    DispatchQueue.main.async { [self] in
      if let timeoutWorkItem {
        timeoutWorkItem.cancel()
      }
      
      if (playbackState.isPlaying) {
        self.timeoutWorkItem = .init(block: { [self] in
          withAnimation(.easeInOut(duration: 0.4), {
            isControlsVisible = false
          })
        })
        
        
        if let timeoutWorkItem {
          DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: timeoutWorkItem)
        }
      }
    }
  }
  
  func cancelTimeoutWorkItem() {
    DispatchQueue.main.async { [self] in
      if let timeoutWorkItem {
        timeoutWorkItem.cancel()
      }
    }
  }
}
