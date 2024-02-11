import Foundation
import SwiftUI
import AVKit

@available(iOS 13.0, *)
class PlayerObserver: ObservableObject {
  @Published var isFinishedPlaying = false
  
  @objc func itemDidFinishPlaying(_ notification: Notification) {
    isFinishedPlaying = true
  }
  
  @objc func playerItemNewAcessLogEntry(_ notification: Notification) {
    guard let player = notification.object as? AVPlayerItem else { return }
//    if player.rate > 0 {
//        print("Player is playing")
//        // Your logic when the player is playing
//    } else {
//        print("Player is paused")
//        // Your logic when the player is paused
//    }
  }
}

@available(iOS 13.0, *)
struct PlayPauseManager : View {
  var player: AVPlayer
  var onTap: (String) -> Void
  
  @ObservedObject private var playerObserver = PlayerObserver()
  @State private var dynamicSize: CGFloat = calculateFrameSize(size22, variantPercent30)
  @State private var imageName: String = ""
  @State private var isFinished: Bool = false
  @State private var status: PlayingStatus = .paused
  
  var body: some View {
    VStack(alignment: .center) {
      HStack {
        Button(action: {
          onPlaybackManager(completionHandler: { completed in
            if completed {
              updateImage()
            }
          })
        }) {
          Image(systemName: imageName)
            .foregroundColor(.white)
            .font(.system(size: dynamicSize))
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .fixedSize(horizontal: true, vertical: true)
    .onAppear {
      updateImage()
      
      NotificationCenter.default.addObserver(
        playerObserver,
        selector: #selector(playerObserver.playerItemNewAcessLogEntry(_:)),
        name: .AVPlayerItemNewAccessLogEntry,
        object: player.currentItem
      )
      
      NotificationCenter.default.addObserver(
        playerObserver,
        selector: #selector(PlayerObserver.itemDidFinishPlaying(_:)),
        name: .AVPlayerItemDidPlayToEndTime,
        object: player.currentItem
      )
      
      NotificationCenter.default.addObserver(
        forName: UIApplication.willChangeStatusBarOrientationNotification,
        object: nil,
        queue: .main
      ) { _ in
        updateDynamicSize()
        updateImage()
      }
    }
    .onReceive(playerObserver.$isFinishedPlaying) { isFinishedPlaying in
      if isFinishedPlaying {
        isFinished = true
        imageName = "gobackward"
        status = .finished
      }
    }
  }
  
}

enum PlayingStatus: String {
  case playing, paused, finished
}

@available(iOS 13.0, *)
extension PlayPauseManager {
  func PlayingStatusManager(_ status: PlayingStatus) -> String {
    switch (status) {
    case .playing:
      return "isPlaying"
    case .paused:
      return "isPaused"
    case .finished:
      return "isFinished"
    }
  }
  
  func onPlaybackManager(completionHandler: @escaping (Bool) -> Void) {
    if isFinished {
      status = .finished
      player.currentItem?.seek(to: CMTime(value: CMTimeValue(0), timescale: 1), completionHandler: completionHandler)
    } else {
      if player.timeControlStatus == .paused  {
        player.play()
        status = .playing
      } else {
        player.pause()
        status = .paused
      }
    }
    updateImage()
    onTap(PlayingStatusManager(status))
  }
  
  func updateImage() {
    guard let currentIem = player.currentItem else { return }
    if player.currentTime().seconds >= (currentIem.duration.seconds - 3) {
      isFinished = true
      imageName = "gobackward"
    } else {
      player.timeControlStatus == .paused ? (imageName = "play.fill") : (imageName = "pause")
      isFinished = false
    }
  }
  
  func updateDynamicSize() {
    dynamicSize = calculateFrameSize(size20, variantPercent30)
  }
}
