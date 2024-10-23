//
//  PlaybackControls.swift
//  Pods
//
//  Created by Michel Gutner on 18/10/24.
//
import SwiftUI
import AVKit

@available(iOS 14.0, *)
struct OverlayViewSwiftUi: View {
  var player: AVPlayer
  var menus: NSDictionary?
  var controls: PlayerControls
  var tapToSeek: NSDictionary?
  var scheduleHideControls: () -> Void
  @Binding var UIControlsProps: HashableUIControls?
  var playbackAction: () -> Void
  var autoPlay: Bool
  
  var fullscreenAction: () -> Void
  @Binding var fullscreenState: Bool
  @State var timeoutWorkItem: DispatchWorkItem? = nil
  
  @State private var interval = CMTime(value: 1, timescale: 2)
  
  @GestureState var isDraggedSeekSlider: Bool = false
  @State var isSeeking: Bool = false
  @State var isSeekingByDoubleTap: Bool = false
  
  @State private var tolerance = CMTime(seconds: 0.1, preferredTimescale: Int32(NSEC_PER_SEC))
  
  @State var thumbnailsUIImageFrames: [UIImage] = []
  
  @State var isFinishedPlaying: Bool = false
  
  @State private var isStarted: Bool = false
  @State private var timeObserver: Any? = nil
  
    @State private var visible: Bool = true
    @State private var alpha: Double = 1.0
    var onTap: () -> Void = {}

    var body: some View {
      VStack {}
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
          Rectangle()
            .fill(Color.black.opacity(0.4))
            .opacity(1 * alpha)
            .animation(.easeInOut(duration: 0.35), value: visible)
            .edgesIgnoringSafeArea(.all)
        )
//        .overlay(
////          DoubleTapManager(
////            onTapBackward: { value in
//////              backwardTime(Double(value))
////              isSeekingByDoubleTap = true
////            },
////            onTapForward: { value in
//////              forwardTime(Double(value))
////              isSeekingByDoubleTap = true
////            },
////            isFinished: {
////              isSeekingByDoubleTap = false
////            },
////            advanceValue: tapToSeek?["value"] as? Int ?? 15,
////            suffixAdvanceValue: tapToSeek?["suffixLabel"] as? String ?? "seconds"
////          )
//        )
        .overlay(
          VStack {
            Spacer()
//            CustomSeekSlider(
//              player: player,
//              UIControlsProps: $UIControlsProps,
//              timeoutWorkItem: $timeoutWorkItem,
//              scheduleHideControls: scheduleHideControls,
//              isDraggedSeekSlider: isDraggedSeekSlider,
//              isSeeking: $isSeeking,
//              isFinishedPlaying: $isFinishedPlaying
//            )
            HStack {
              Spacer()
              Menus(options: menus, controls: controls)
              FullScreen(fullScreen: $fullscreenState, action: fullscreenAction)
            }
          }
          .opacity(visible ? 1 : 0)
          .animation(.easeInOut(duration: 0.35), value: visible)
        )
        .overlay(
            Circle()
              .fill(.black.opacity(0.50))
              .frame(width: 60, height: 60)
              .overlay(
                Group {
                  if isFinishedPlaying {
//                    Button(action: resetPlaybackStatus) {
//                      Image(systemName: "gobackward")
//                        .font(.system(size: 35))
//                        .foregroundColor(Color(uiColor: UIControlsProps?.playback.color ?? .white))
//                    }
                  } else {
                    if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                      CustomLoading(color: UIControlsProps?.loading.color)
                    } else {
//                      CustomPlayPauseButton(
//                        action: playbackAction,
//                        isPlaying: autoPlay,
//                        frame: .init(origin: .zero, size: .init(width: 30, height: 30)),
//                        color: UIControlsProps?.playback.color?.cgColor
//                      )
//                      .onAppear {
//                        scheduleHideControls()
//                      }
                    }
                  }
                }
              )
              .frame(width: 60, height: 60)
              .opacity(visible && !isSeeking && !isSeekingByDoubleTap ? 1 : 0)
        )
      .onTapGesture {
        toggle()
        onTap()
      }
    }
    
    func didHide() {
        self.alpha = 0.001
        self.visible = false
    }
    
    func didShow() {
        self.alpha = 1
        self.visible = true
    }
    
    func toggle() {
        if visible {
            didHide()
        } else {
            didShow()
        }
    }
}
