//
//  MediaPlayerObservable.swift
//  Pods
//
//  Created by Michel Gutner on 05/01/25.
//

import Combine

open class SharedPlaybackState: ObservableObject {
    public static let instance = SharedPlaybackState()
    private init() {}
    
    @Published public var isPlaying: Bool = false
    @Published public var isReady: Bool = false
    
    internal static func updateIsPlaying(to value: Bool) {
      SharedPlaybackState.instance.isPlaying = value
    }
  
    internal static func setIsReadyForDisplay(to value: Bool) {
      SharedPlaybackState.instance.isReady = value
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
  
  internal static func addThumbnail(_ thumbnail: UIImage) {
    DispatchQueue.main.async {
      ThumbnailManager.shared.images.append(thumbnail)
    }
  }
  
  internal static func clearThumbnails() {
    DispatchQueue.main.async {
      ThumbnailManager.shared.images.removeAll()
    }
  }
}
