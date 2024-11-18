//
//  Overlay.swift
//  Pods
//
//  Created by Michel Gutner on 24/10/24.
//

import SwiftUI
import AVKit

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
  @State private var showOverlay = false
  
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
            Button(action: {
              guard let player else { return }
              if player.timeControlStatus == .paused {
                player.play()
              } else {
                player.pause()
              }
            }, label: {
                Image(systemName: "play.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            })
            .opacity(showOverlay ? 1 : 0.0001)
            .animation(.easeInOut(duration: 0.35), value: showOverlay)
        
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
    }
    .onAppear {
      scheduleHideControls()
    }
  }
}
