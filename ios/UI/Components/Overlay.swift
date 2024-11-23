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
  @ObservedObject var observable: ObservableObjectManager
  
  weak var player: AVPlayer?
  var scheduleHideControls: () -> Void
  var advanceValue: Int
  var suffixAdvanceValue: String
  var onTapFullscreen: (() -> Void)?
  @Binding var menus: NSDictionary?
  
  @State private var isTapped: Bool = false
  @State private var isTappedLeft: Bool = false
  @State private var showOverlay = true // TODO: must be initial false
  
  @State private var playPauseTransparency = 0.0

  @State private var cancellables = Set<AnyCancellable>()
  
  @State private var selectedOptionItem: [String: String] = [:]

  var body: some View {
    ZStack {
      LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.4), Color.black.opacity(0.1), Color.black.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .ignoresSafeArea()
      HStack(spacing: StandardSizes.large55) {
        DoubleTapSeek(isTapped: $isTappedLeft, onTap:  onBackwardTime, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: scheduleHideControls)
        DoubleTapSeek(isTapped: $isTapped, isForward: true, onTap:  onForwardTime, advanceValue: advanceValue, suffixAdvanceValue: suffixAdvanceValue, isFinished: scheduleHideControls)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .opacity(showOverlay ? 1 : 0.0001)
    .animation(.easeInOut(duration: 0.35), value: showOverlay)
    .overlay(
      ZStack(alignment: .center) {
        if observable.isBuffering {
            CustomLoading(color: UIColor.white)
        } else {
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
              
              
              // Ícone de pausa
              Image(systemName: "pause.fill")
                .font(.system(size: 55))
                .foregroundColor(.white)
                .scaleEffect(observable.isPlaying ? 1 : 0)
                .opacity(observable.isPlaying ? 1 : 0)
                .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: observable.isPlaying)
              
              // Ícone de play
              Image(systemName: "play.fill")
                .font(.system(size: 55))
                .foregroundColor(.white)
                .scaleEffect(!observable.isPlaying ? 1 : 0)
                .opacity(!observable.isPlaying ? 1 : 0)
                .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: observable.isPlaying)
              
            }
          }
          .opacity(showOverlay ? 1 : 0.0001)
          .animation(.easeInOut(duration: 0.35), value: showOverlay)
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
                      .padding(8)
//                      .background(Color.black.opacity(0.4))
                      .foregroundColor(.white)
                      .font(.system(size: 20))
//                      .clipShape(Circle())
              }
              
              Button(action: {
                onTapFullscreen?()
              }, label: {
                Image(systemName: observable.isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                  .rotationEffect(.degrees(90))
                  .frame(width: 20, height: 20)
                  .padding(8)
                  .foregroundColor(.white)
                  .font(.system(size: 20))
              })
            }
            CustomSeekSlider(player: player, observable: observable, UIControlsProps: .constant(.none), cancelTimeoutWorkItem: {}, scheduleHideControls: {}, canPlaying: {})
          }
          .padding()
          .offset(y: showOverlay ? 0 : 5)
          .opacity(showOverlay ? 1 : 0)
          .animation(.easeInOut(duration: 0.2), value: showOverlay)
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
    .onReceive(NotificationCenter.default.publisher(for: .AVPlayerUrlChanged), perform: { output in
      guard let newUrl = output.object as? String else { return }
      replacePlayerWithNewUrl(url: newUrl)
    })
    .onReceive(NotificationCenter.default.publisher(for: .AVPlayerRateDidChange), perform: { output in
      guard let newRate = output.object as? Float else { return }
      DispatchQueue.main.async(execute: { [self] in
        if (self.player?.timeControlStatus == .playing) {
          self.player?.rate = newRate
        }
      })
    })
    .onAppear {
      scheduleHideControls()
      setupPlayerObservation()
    }
    .onDisappear {
      menus = [:]
    }
  }
  

  
}

@available(iOS 14.0, *)
extension OverlayManager {
  private func setupPlayerObservation() {
    guard let player else { return }
    
    player.publisher(for: \.timeControlStatus)
        .sink { [self] status in
            observable.isPlaying = (status == .playing)
            observable.isBuffering = (status == .waitingToPlayAtSpecifiedRate)
        }
        .store(in: &cancellables)
  }
  
  private func togglePlayback() {
    DispatchQueue.main.async { [self] in
      guard let player else { return }
      if player.timeControlStatus == .playing {
        player.pause()
      } else {
        player.play()
        player.rate = observable.newRate
//        self.scheduleHideControls()
      }
    }
  }
  
  private func onBackwardTime(_ timeToChange: Int) {
    guard let player else { return }
    guard let currentItem = player.currentItem else { return }
    
    let currentTime = CMTimeGetSeconds(player.currentTime())
    let newTime = max(currentTime - Double(timeToChange), 0)
    player.seek(to: CMTime(seconds: newTime, preferredTimescale: currentItem.duration.timescale),
                toleranceBefore: .zero,
                toleranceAfter: .zero,
                completionHandler: { _ in })
  }
  
  private func onForwardTime(_ timeToChange: Int) {
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
  
  private func replacePlayerWithNewUrl(url: String) {
    guard let player = player else { return }
    let newUrl = URL(string: url)
    
    if (newUrl == observable.urlOfCurrentPlayerItem(to: player)) {
      return
    }
    
    let currentTime = player.currentItem?.currentTime() ?? CMTime.zero
    let asset = AVURLAsset(url: newUrl!)
    let newPlayerItem = AVPlayerItem(asset: asset)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
      player.replaceCurrentItem(with: newPlayerItem)
      player.seek(to: currentTime)
    
      var playerItemStatusObservation: NSKeyValueObservation?
      playerItemStatusObservation = newPlayerItem.observe(\.status, options: [.new]) { (item, _) in
        NotificationCenter.default.post(name: .AVPlayerErrors, object: extractPlayerItemError(item))
        guard item.status == .readyToPlay else {
          return
        }
        playerItemStatusObservation?.invalidate()
      }
    })
  }
}
