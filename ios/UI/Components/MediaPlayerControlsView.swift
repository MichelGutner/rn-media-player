//
//  Overlay.swift
//  Pods
//
//  Created by Michel Gutner on 24/10/24.
//

import SwiftUI
import AVKit
import Combine

public enum MediaPlayerControlsViewType {
  case playPause
  case fullscreen
  case optionsMenu
}

@available(iOS 14.0, *)
public protocol MediaPlayerControlsViewDelegate : AnyObject {
  func controlDidTap(_ control: MediaPlayerControlsView, controlType: MediaPlayerControlsViewType)
  func controlDidTap(_ control: MediaPlayerControlsView, controlType: MediaPlayerControlsViewType, optionMenuSelected option: ((String, Any)))
  func sliderDidChange(_ control: MediaPlayerControlsView, didChangeFrom fromValue: Double, didChangeTo toValue: CMTime)
}

@available(iOS 14.0, *)
public struct MediaPlayerControlsView : View {
  @ObservedObject private var playbackState = PlaybackStateObservable.shared
  @ObservedObject private var screenState = ScreenStateObservable.shared
  
  @ObservedObject var mediaSession = MediaSessionManager()
  @ObservedObject var observable = MediaPlayerObservable()
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
            mediaSession: mediaSession
          )
          DoubleTapSeek(
            isTapped: $isTapped,
            mediaSession: mediaSession,
            isForward: true
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
          .opacity(isControlsVisible && !isSeeking ? 1 : 0)
          .animation(.easeInOut(duration: 0.2), value: isControlsVisible || isSeeking)
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
            .opacity(isControlsVisible && !isSeeking ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isControlsVisible || isSeeking)
            
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
                }, label: {
                  Image(systemName: observable.isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .rotationEffect(.degrees(90))
                    .padding(EdgeInsets.init(top: 12, leading: 12, bottom: 4, trailing: 12))
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                })
                .background(Color.clear)
                .clipShape(Circle())
              }
              .opacity(isSeeking ? 0 : 1)
              .animation(.easeInOut(duration: 0.2), value: isSeeking)
              
              // SeekSlider Control
              //              MediaPlayerSeekSlider()
              InteractiveMediaSeekSlider(player: Shared.instance.source?.player, isSeeking: $isSeeking)
            }
            .offset(y: isControlsVisible ? 0 : 5)
            .opacity(isControlsVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isControlsVisible)
          }
          .padding(16)
          .background(Color.clear)
        }
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
        scheduleHideControls()
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
  
  
//  @ViewBuilder
//  @available(iOS 14.0, *)
//  private func MediaPlayerSeekSlider() -> some View {
//    ZStack {
//      VStack {
//        MediaSeekSliderView(
//          viewModel: observable,
//          onProgressBegan: { _ in
//            lastProgress = observable.currentTime / observable.duration
//            startSliderProgressFrom = observable.currentTime
//
//            showThumbnails = true
//            observable.updateIsSeeking(to: true)
//            //            mediaSession.cancelTimeoutWorkItem()
//          },
//          
//          onProgressChanged: { progress in
//            let draggIndex = Int(observable.sliderProgress / 0.01)
//            
//            if thumbnailsUIImageFrames.indices.contains(draggIndex) {
//              draggingImage = thumbnailsUIImageFrames[draggIndex]
//            }
//          },
//          onProgressEnded: { progress in
//            showThumbnails = false
//            let progressInSeconds = observable.duration * progress
//            let lastProgressInSeconds = observable.duration * lastProgress
////
//            let targetTime = CMTime(seconds: progressInSeconds, preferredTimescale: 600)
////
////            NotificationCenter.default.post(name: .EventSeekBar, object: nil, userInfo: ["start": (lastProgress, lastProgressInSeconds), "ended": (progress, progressInSeconds)])
//            delegate?.sliderDidChange(self, didChangeFrom: startSliderProgressFrom, didChangeTo: targetTime)
//          }
//        )
//        .frame(height: 24)
//        .scaleEffect(x: observable.isSeeking ? 1.03 : 1, y: observable.isSeeking ? 1.5 : 1, anchor: .bottom)
//        .animation(.interpolatingSpring(stiffness: 100, damping: 30, initialVelocity: 0.2), value: observable.isSeeking)
//        
//        HStack {
//          TimeCodes(time: .constant(observable.currentTime), UIControlsProps: .constant(.none))
//          Spacer()
//          TimeCodes(time: .constant(observable.duration - observable.currentTime), UIControlsProps: .constant(.none), suffixValue: "-")
//        }
//      }
//      .overlay(
//        HStack {
//          GeometryReader { geometry in
//            Thumbnails(
//              duration: .constant(observable.duration),
//              geometry: geometry,
//              UIControlsProps: .constant(.none),
//              sliderProgress: .constant(observable.sliderProgress),
//              isSeeking: $showThumbnails,
//              draggingImage: $draggingImage
//            )
//            Spacer()
//          }
//        }
//      )
//    }
//    .background(Color.clear)
//    .frame(maxWidth: .infinity)
//  }

  
}

//@available(iOS 14.0, *)
//extension MediaPlayerControlsView {
//  private func togglePlayback() {
//    guard let player = mediaSession.player else { return }
//    DispatchQueue.main.async { [self] in
//      if mediaSession.isFinished {
//        player.seek(to: .zero)
//        player.play()
//        mediaSession.isFinished = false
//      }
//      
//      if player.timeControlStatus == .playing {
//        player.pause()
//        mediaSession.cancelTimeoutWorkItem()
//        NotificationCenter.default.post(name: .EventPlayPause, object: false)
//      } else {
//        player.play()
//        scheduleHideControls()
//        player.rate = mediaSession.newRate
//        NotificationCenter.default.post(name: .EventPlayPause, object: true)
//      }
//    }
//  }
//  
//
//}
