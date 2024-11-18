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
  weak var player: AVPlayer? 
  var onTapBackward: (Int) -> Void
  var onTapForward: (Int) -> Void
  var scheduleHideControls: () -> Void
  var advanceValue: Int
  var suffixAdvanceValue: String
  var onTapOverlay: () -> Void
  var onTapFullscreen: (() -> Void)?
  
  @State private var isTapped: Bool = false
  @State private var isTappedLeft: Bool = false
  @State private var showOverlay = true // TODO: must be initial false
  
  @State private var isBuffering = false
  @State private var isPlaying = false
  
  @State private var cancellables = Set<AnyCancellable>()
  
  var body: some View {
    ZStack {
      HStack(spacing: StandardSizes.large55) {
        DoubleTapSeek(isTapped: $isTappedLeft, onTap:  onTapBackward, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: scheduleHideControls)
        DoubleTapSeek(isTapped: $isTapped, isForward: true, onTap:  onTapForward, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: scheduleHideControls)
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
                HStack {
                    Spacer()
                    Button(action: {
                        onTapFullscreen?()
                    }, label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .resizable()
                            .frame(width: 14, height: 14)
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    })
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
      print("testingx") // must be checked if can be not removed when transition to full screen
    }
  }
  
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
}
