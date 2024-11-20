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
struct OverlayManager : View {
  @ObservedObject private var observable = ObservableObjectManager()
  
  weak var player: AVPlayer?
  var scheduleHideControls: () -> Void
  var advanceValue: Int
  var suffixAdvanceValue: String
  var onTapOverlay: () -> Void
  var onTapFullscreen: (() -> Void)?
  @Binding var menus: NSDictionary?
  
  @State private var isTapped: Bool = false
  @State private var isTappedLeft: Bool = false
  @State private var showOverlay = true // TODO: must be initial false
  
  @State private var isBuffering = false
  @State private var isPlaying = false
  
  @State private var cancellables = Set<AnyCancellable>()
  
  @State private var selectedOptionItem: [String: String] = [:]
  
  ////
  ///
  ///
  ///

  var body: some View {
    ZStack {
      HStack(spacing: StandardSizes.large55) {
        DoubleTapSeek(isTapped: $isTappedLeft, onTap:  onBackwardTime, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: scheduleHideControls)
        DoubleTapSeek(isTapped: $isTapped, isForward: true, onTap:  onForwardTime, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: scheduleHideControls)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.2))
    .ignoresSafeArea(.all)
    .opacity(showOverlay ? 1 : 0.0001)
    .animation(.easeInOut(duration: 0.35), value: showOverlay)
    .overlay(
      ZStack(alignment: .center) {
        if let player = player {
          if isBuffering {
            CustomLoading(color: UIColor.white)
          } else {
            Button(action: {
              if player.timeControlStatus == .paused {
                player.play()
              } else {
                player.pause()
              }
            }) {
              Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .padding()
                .background(Color.black.opacity(0.4))
                .foregroundColor(.white)
                .clipShape(Circle())
            }
            .opacity(showOverlay ? 1 : 0.0001)
            .animation(.easeInOut(duration: 0.35), value: showOverlay)
          }
        }
        
        VStack {
          Spacer()
          VStack {
            HStack {
              Spacer()
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
                                          // controls.optionSelected(option.key, value)
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
                  Image(systemName: "ellipsis")
                      .frame(width: 20, height: 20)
                      .padding(8)
                      .background(Color.black.opacity(0.4))
                      .foregroundColor(.white)
                      .clipShape(Circle())
              }
              
              Button(action: {
                onTapFullscreen?()
              }, label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                  .frame(width: 20, height: 20)
                  .padding(.all, 8)
                  .background(Color.black.opacity(0.4))
                  .foregroundColor(.white)
                  .clipShape(Circle())
              })
            }
            CustomSeekSlider(player: player, observable: observable, UIControlsProps: .constant(.none), cancelTimeoutWorkItem: {}, scheduleHideControls: {}, canPlaying: {})
          }
          .padding()
          .opacity(showOverlay ? 1 : 0.0001)
          .animation(.easeInOut(duration: 0.35), value: showOverlay)
        }
      }
        .background(Color.clear) // Unsure player layer interactable
    )

    .onTapGesture {
      showOverlay.toggle()
      if showOverlay {
          scheduleHideControls()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification), perform: { output in
      print("Player chegou ao fim do vídeo.")
    })
    .onAppear {
      scheduleHideControls()
      setupPlayerObservation()
    }
    .onDisappear {
      menus = [:]
      print("testingx") // must be checked if can be not removed when transition to full screen
    }
  }
  

  
}

@available(iOS 14.0, *)
extension OverlayManager {
  private func setupPlayerObservation() {
    guard let player else { return }
    
    // Observe the timeControlStatus using Combine
    player.publisher(for: \.timeControlStatus)
      .sink { [self] status in
        switch status {
        case .playing:
          self.isPlaying = true
          self.isBuffering = false
        case .paused:
          self.isPlaying = false
          self.isBuffering = false
        case .waitingToPlayAtSpecifiedRate:
          self.isBuffering = true
        @unknown default:
          break
        }
      }
      .store(in: &self.cancellables)
  }
  
  func onBackwardTime(_ timeToChange: Int) {
    guard let player else { return }
    guard let currentItem = player.currentItem else { return }
    
    let currentTime = CMTimeGetSeconds(player.currentTime())
    let newTime = max(currentTime - Double(timeToChange), 0)
    player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                toleranceBefore: .zero,
                toleranceAfter: .zero,
                completionHandler: { _ in })
  }
  
  func onForwardTime(_ timeToChange: Int) {
    guard let player else { return }
    guard let currentItem = player.currentItem else { return }
    let currentTime = CMTimeGetSeconds(player.currentTime())
    
    let newTime = max(currentTime + Double(timeToChange), 0)
    player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                toleranceBefore: .zero,
                toleranceAfter: .zero,
                completionHandler: { _ in })
  }
  
  private var menuOptions: [(key: String, values: NSDictionary)] {
      guard let menus = menus else { return [] }
      return menus.compactMap { (key, value) in
          guard let key = key as? String, let values = value as? NSDictionary else { return nil }
          return (key: key, values: values)
      }
  }

}

@available(iOS 14.0, *)
extension OverlayManager {}
