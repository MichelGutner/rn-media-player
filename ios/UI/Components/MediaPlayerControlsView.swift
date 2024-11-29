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
struct MediaPlayerControlsView : View {
  @ObservedObject var mediaSession: MediaSessionManager
  var onTapFullscreen: (() -> Void)?
  @Binding var menus: NSDictionary?
  @State private var isTapped: Bool = false
  @State private var isTappedLeft: Bool = false
  
  @State private var playPauseTransparency = 0.0
  @State private var selectedOptionItem: [String: String] = [:]
  
  @State private var sliderProgress: CGFloat = 0.0
  @State private var bufferingProgress: CGFloat = 0.0

  var body: some View {
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
          mediaSession: mediaSession,
          seekValue: mediaSession.tapToSeek?.seekValue,
          suffixSeekValue: mediaSession.tapToSeek?.suffixSeekValue
        )
        DoubleTapSeek(
          isTapped: $isTapped,
          mediaSession: mediaSession,
          isForward: true,
          seekValue: mediaSession.tapToSeek?.seekValue,
          suffixSeekValue: mediaSession.tapToSeek?.suffixSeekValue
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .opacity(mediaSession.isControlsVisible ? 1 : 0.0001)
    .animation(.easeInOut(duration: 0.35), value: mediaSession.isControlsVisible)
    .overlay(
      ZStack(alignment: .center) {
        if mediaSession.isBuffering {
            CustomLoading(color: UIColor.white)
        } else {
          // PlayPause Control ---
          Button(action: {
            togglePlayback()
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
                .scaleEffect(mediaSession.isPlaying ? 1 : 0)
                .opacity(mediaSession.isPlaying ? 1 : 0)
                .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: mediaSession.isPlaying)
              
              Image(systemName: "play.fill")
                .font(.system(size: 55))
                .foregroundColor(.white)
                .scaleEffect(mediaSession.isPlaying == false ? 1 : 0)
                .opacity(mediaSession.isPlaying == false ? 1 : 0)
                .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: mediaSession.isPlaying)
              
            }
          }
          .opacity(mediaSession.isControlsVisible && !mediaSession.isSeeking ? 1 : 0)
          .animation(.easeInOut(duration: 0.2), value: mediaSession.isControlsVisible || mediaSession.isSeeking)
          .onAppear {
            mediaSession.scheduleHideControls()
          }
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
              // Menu Control
              Menu {
                ForEach(menuOptions, id: \.key) { option in
                  let values = option.values["data"] as? [NSDictionary] ?? []
                  let initialSelected = option.values["initialItemSelected"] as? String
                  let currentSelection = selectedOptionItem[option.key]
                  
                  Menu(option.key) {
                    ForEach(values, id: \.self) { item in
                      if let name = item["name"] as? String {
                        let isSelected = currentSelection == name || (currentSelection == nil && name == initialSelected)
                        
                        Button(action: {
                          if let value = item["value"] {
                            selectedOptionItem[option.key] = name
                            NotificationCenter.default.post(name: .MenuSelectedOption, object: (option.key, value))
                          }
                        }) {
                          if #available(iOS 14.5, *) {
                            if isSelected {
                              Label(name, systemImage: "checkmark")
                                .labelStyle(.titleAndIcon)
                            } else {
                              Text(name)
                            }
                          } else {
                            if isSelected {
                              Label(name, systemImage: "checkmark")
                            } else {
                              Text(name)
                            }
                          }
                        }
                      }
                    }
                  }
                }
              } label: {
                Image(systemName: "ellipsis.circle")
                  .frame(width: 20, height: 20)
                  .padding(.horizontal, 8)
                  .foregroundColor(.white)
                  .font(.system(size: 20))
                
              }
              
              // Fullscreen Control
              Button(action: {
                onTapFullscreen?()
              }, label: {
                ZStack {
                  Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .rotationEffect(.degrees(90))
                    .padding(.horizontal, 8)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .scaleEffect(mediaSession.isFullscreen ? 1 : 0)
                    .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: mediaSession.isFullscreen)
                  
                  Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .rotationEffect(.degrees(90))
                    .frame(width: 20, height: 20)
                    .padding(.horizontal, 8)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .scaleEffect(mediaSession.isFullscreen ? 0 : 1)
                    .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: mediaSession.isFullscreen)
                }
              })
            }
            .opacity(mediaSession.isSeeking ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: mediaSession.isSeeking)
            
            // SeekSlider Control
            InteractiveMediaSeekSlider(mediaSession: mediaSession, UIControlsProps: .constant(.none))
          }
          .offset(y: mediaSession.isControlsVisible ? 0 : 5)
          .opacity(mediaSession.isControlsVisible ? 1 : 0)
          .animation(.easeInOut(duration: 0.2), value: mediaSession.isControlsVisible)
        }
        .padding(16)
      }
        .background(Color.clear) // Unsure player layer interactable
    )
    .onTapGesture {
      mediaSession.toggleControls()
      if mediaSession.isControlsVisible {
          mediaSession.scheduleHideControls()
      }
    }
    .onDisappear {
      menus = [:]
    }
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
  
  private var menuOptions: [(key: String, values: NSDictionary)] {
    guard let menus = menus else { return [] }
    return menus.compactMap { (key, value) in
      guard let key = key as? String, let values = value as? NSDictionary else { return nil }
      return (key: key, values: values)
    }
  }
}
