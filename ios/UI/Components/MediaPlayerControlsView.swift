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
}

@available(iOS 14.0, *)
public struct MediaPlayerControlsView : View {
  @Binding var isPlaying: Bool
  @ObservedObject var mediaSession: MediaSessionManager
  var onTapFullscreen: (() -> Void)?
  @Binding var menus: NSDictionary?
  @ObservedObject var viewModel: MediaPlayerObservable
  
  var onPlayPause: (() -> Void)?
  @State private var isTapped: Bool = false
  @State private var isTappedLeft: Bool = false
  
  @State private var playPauseTransparency = 0.0
  @State private var bufferingProgress: CGFloat = 0.0
  
  public weak var delegate: MediaPlayerControlsViewDelegate?

  public var body: some View {
    ZStack{
//      CustomLoading(color: .white)
//        .opacity(mediaSession.isReady ? 0 : 1)
      
      ZStack {
        // Gradient Background ---
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
      .opacity(mediaSession.isControlsVisible ? 1 : 0.0001)
      .animation(.easeInOut(duration: 0.35), value: mediaSession.isControlsVisible)
      .overlay(
        ZStack(alignment: .center) {
          Button(action: {
            delegate?.controlDidTap(self, controlType: .playPause)
            playPauseTransparency = 0.6
            withAnimation(.easeIn(duration: 0.2), {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                playPauseTransparency = 0.0
              })
            })
          }) {
            ZStack {
              Circle()
                .fill(Color(uiColor: .systemFill))
                .frame(width: 80, height: 80)
                .opacity(playPauseTransparency)
              
              Image(systemName: "pause.fill")
                .font(.system(size: 55))
                .foregroundColor(.white)
                .scaleEffect(viewModel.isPlaying ? 1 : 0)
                .opacity(viewModel.isPlaying ? 1 : 0)
                .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: viewModel.isPlaying)
              
              Image(systemName: "play.fill")
                .font(.system(size: 55))
                .foregroundColor(.white)
                .scaleEffect(!viewModel.isPlaying ? 1 : 0)
                .opacity(!viewModel.isPlaying ? 1 : 0)
                .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: viewModel.isPlaying)
              
            }
          }
          .opacity(mediaSession.isControlsVisible && !mediaSession.isSeeking ? 1 : 0)
          .animation(.easeInOut(duration: 0.2), value: mediaSession.isControlsVisible || mediaSession.isSeeking)
          .onAppear {
            mediaSession.scheduleHideControls()
          }
          
          
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
            .offset(y: mediaSession.isControlsVisible ? 0 : -5)
            .opacity(mediaSession.isControlsVisible && !mediaSession.isSeeking ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: mediaSession.isControlsVisible || mediaSession.isSeeking)
            
            Spacer()
            
            VStack {
              Spacer()
              HStack {
                Spacer()
                CustomMenus(menus: $menus)
                  .background(Color.clear)
                  .clipShape(Circle())
                
                Button(action: {
                  delegate?.controlDidTap(self, controlType: .fullscreen)
                }, label: {
                  /// "arrow.up.left.and.arrow.down.right"
                  Image(systemName: viewModel.isFullScreen ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                      .rotationEffect(.degrees(90))
                      .padding(EdgeInsets.init(top: 12, leading: 12, bottom: 4, trailing: 12))
                      .foregroundColor(.white)
                      .font(.system(size: 20))
//                      .scaleEffect(isFullscreen ? 1 : 0)
//                      .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: isFullscreen)
                })
                .background(Color.clear)
                .clipShape(Circle())
              }
              .opacity(mediaSession.isSeeking ? 0 : 1)
              .animation(.easeInOut(duration: 0.2), value: mediaSession.isSeeking)
              
              // SeekSlider Control
              InteractiveMediaSeekSlider(viewModel: viewModel, UIControlsProps: .constant(.none))
            }
            .offset(y: mediaSession.isControlsVisible ? 0 : 5)
            .opacity(mediaSession.isControlsVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: mediaSession.isControlsVisible)
          }
          .padding(16)
          .background(Color.clear)
        }
      )
      .onTapGesture {
        if mediaSession.isReady {
          mediaSession.toggleControls()
          if mediaSession.isControlsVisible {
            mediaSession.scheduleHideControls()
          }
        }
      }
      .onDisappear {
        menus = [:]
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  

  
}

@available(iOS 14.0, *)
extension MediaPlayerControlsView {
  private func togglePlayback() {
    guard let player = mediaSession.player else { return }
    DispatchQueue.main.async { [self] in
      if mediaSession.isFinished {
        player.seek(to: .zero)
        player.play()
        mediaSession.isFinished = false
      }
      
      if player.timeControlStatus == .playing {
        player.pause()
        mediaSession.cancelTimeoutWorkItem()
        NotificationCenter.default.post(name: .EventPlayPause, object: false)
      } else {
        player.play()
        mediaSession.scheduleHideControls()
        player.rate = mediaSession.newRate
        NotificationCenter.default.post(name: .EventPlayPause, object: true)
      }
    }
  }
  

}
