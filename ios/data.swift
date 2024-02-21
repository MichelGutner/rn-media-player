//
//  SpeedRateData.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 30/01/24.
//

@available(iOS 13.0, *)
public var playbackSpeedData: [HashbleItem] = [
  HashbleItem(name: "0.5x", value: "0.5", enabled: true),
  HashbleItem(name: "0.75x", value: "0.75", enabled: true),
  HashbleItem(name: "Normal", value: "1", enabled: true),
  HashbleItem(name: "1.25x", value: "1.25", enabled: true),
  HashbleItem(name: "1.5x", value: "1.5", enabled: true),
  HashbleItem(name: "2.0x", value: "2.0", enabled: true)
]

@available(iOS 13.0, *)
public var qualityOptionsData: [HashbleItem] = [
    HashbleItem(name: "144p", enabled: true),
    HashbleItem(name: "240p", enabled: true),
    HashbleItem(name: "360p", enabled: true),
    HashbleItem(name: "480p", enabled: true),
    HashbleItem(name: "720p", enabled: true),
    HashbleItem(name: "1080p", enabled: true),
    HashbleItem(name: "1440p", enabled: false),
    HashbleItem(name: "2160p", enabled: false),
    HashbleItem(name: "2880p", enabled: false),
    HashbleItem(name: "4320p", enabled: false)
]


@available(iOS 13.0, *)
public var settingsData: [HashbleItem] = [
  HashbleItem(name: "Quality", value: "quality", enabled: true),
  HashbleItem(name: "Playback speed", value: "playbackSpeed", enabled: true),
  HashbleItem(name: "More Options", value: "moreOptions", enabled: true)
]
