//
//  MediaPlayerObservable.swift
//  Pods
//
//  Created by Michel Gutner on 05/01/25.
//

import Combine

open class PlaybackManager: ObservableObject {
  public static let shared = PlaybackManager()
  private init() {}
  
  @Published public var isPlaying: Bool = false
  @Published public var isReady: Bool = false
  @Published public var currentTime: Double = 0.0
  @Published public var currentTimePercent: Double = 0.0
  @Published public var duration: Double = 0.0
  @Published public var buffering: CGFloat = 0.0
  
  internal static func updateIsPlaying(to value: Bool) {
    PlaybackManager.shared.isPlaying = value
  }
  
  internal static func setIsReadyForDisplay(to value: Bool) {
    PlaybackManager.shared.isReady = value
  }
  
  internal static func setPlaybackTimes(currentTime: Double, duration: Double, buffering: CGFloat) {
    PlaybackManager.shared.currentTime = currentTime
    PlaybackManager.shared.currentTimePercent = currentTime / duration
    PlaybackManager.shared.duration = duration
    PlaybackManager.shared.buffering = buffering
  }
}

public class SharedScreenState: ObservableObject {
    public static let instance = SharedScreenState()
    private init() {}
    @Published public var isFullScreen: Bool = false
    
    internal static func setFullscreenState(to value: Bool) {
      SharedScreenState.instance.isFullScreen = value
    }
}

public class SharedMetadataIdentifier: ObservableObject {
  public static let instance = SharedMetadataIdentifier()
  private init() {}
  @Published public var title: String = ""
  @Published public var artist: String = ""
  
  internal static func setMetadata(title: String, artist: String) {
    SharedMetadataIdentifier.instance.title = title
    SharedMetadataIdentifier.instance.artist = artist
  }
}

public class ThumbnailManager: ObservableObject {
  public static let shared = ThumbnailManager()
  private init() {}
  @Published public var images: [UIImage] = []
  
  internal static func setImage(_ image: UIImage) {
    DispatchQueue.main.async {
      ThumbnailManager.shared.images.append(image)
    }
  }
  
  internal static func clearImages() {
    DispatchQueue.main.async {
      ThumbnailManager.shared.images.removeAll()
    }
  }
}

public class RCTConfigManager : ObservableObject {
  public static var shared = RCTConfigManager()
  
  private var doubleTapToSeek : NSDictionary = [
    "value": 10,
    "suffixLabel": "seconds"
  ]
  
  @Published public var data: RCTConfigData!
  
  private init() {
    data = RCTConfigData()
  }

  internal static func setDoubleTapToSeek(with config: NSDictionary? = [:]) {
    let defaultConfig : NSDictionary = [
      "value": 10,
      "suffixLabel": "seconds"
    ]
    
    let finalConfig = (config != nil && config?.count ?? 0 > 0) ? config! : defaultConfig
    
    Debug.log("default finalConfig: \(finalConfig)")
    
    RCTConfigManager.shared.data.setDoubleTapToSeek(dictionary: finalConfig)
  }
}

public class RCTConfigData {
  public init() {}
  
    public struct DoubleTapConfig {
        public let value: Int
        public let suffixLabel: String

        public init(dictionary: NSDictionary) {
            self.value = dictionary["value"] as? Int ?? 0
            self.suffixLabel = dictionary["suffixLabel"] as? String ?? ""
        }
    }

    public var doubleTapToSeek: DoubleTapConfig!

    public func setDoubleTapToSeek(dictionary: NSDictionary) {
        self.doubleTapToSeek = DoubleTapConfig(dictionary: dictionary)
    }
}

