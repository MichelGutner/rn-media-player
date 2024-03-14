//
//  ControllersProps.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 13/03/24.
//

struct PlaybackControlHashableProps: Hashable {
    var color: UIColor

    init(color: UIColor) {
        self.color = color
    }

    init(dictionary: NSDictionary?) {
        self.color = transformStringIntoUIColor(color: dictionary?["color"] as? String)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(color)
    }

    static func == (lhs: PlaybackControlHashableProps, rhs: PlaybackControlHashableProps) -> Bool {
        return lhs.color == rhs.color
    }
}

struct SeekSliderControlHashableProps : Hashable {
  var maximumTrackColor: UIColor
  var minimumTrackColor: UIColor
  var seekableTintColor: UIColor
  var thumbImageColor: UIColor
  var thumbnailBorderColor: UIColor
  var thumbnailTimeCodeColor: UIColor
  
  init(maximumTrackColor: UIColor, minimumTrackColor: UIColor, seekableTintColor: UIColor, thumbImageColor: UIColor, thumbnailBorderColor: UIColor, thumbnailTimeCodeColor: UIColor) {
    self.maximumTrackColor = maximumTrackColor
    self.minimumTrackColor = minimumTrackColor
    self.seekableTintColor = seekableTintColor
    self.thumbImageColor = thumbImageColor
    self.thumbnailBorderColor = thumbnailBorderColor
    self.thumbnailTimeCodeColor = thumbnailTimeCodeColor
  }
  
  init(dictionary: NSDictionary?) {
    self.maximumTrackColor = transformStringIntoUIColor(color: dictionary?["maximumTrackColor"] as? String)
    self.minimumTrackColor = transformStringIntoUIColor(color: dictionary?["minimumTrackColor"] as? String)
    self.seekableTintColor = transformStringIntoUIColor(color: dictionary?["seekableTintColor"] as? String)
    self.thumbImageColor = transformStringIntoUIColor(color: dictionary?["thumbImageColor"] as? String)
    self.thumbnailBorderColor = transformStringIntoUIColor(color: dictionary?["thumbnailBorderColor"] as? String)
    self.thumbnailTimeCodeColor = transformStringIntoUIColor(color: dictionary?["thumbnailTimeCodeColor"] as? String)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(maximumTrackColor)
    hasher.combine(minimumTrackColor)
    hasher.combine(seekableTintColor)
    hasher.combine(thumbImageColor)
    hasher.combine(thumbnailBorderColor)
    hasher.combine(thumbnailTimeCodeColor)
  }
  
  static func == (lhs: SeekSliderControlHashableProps, rhs: SeekSliderControlHashableProps) -> Bool {
         return lhs.maximumTrackColor == rhs.maximumTrackColor &&
             lhs.minimumTrackColor == rhs.minimumTrackColor &&
             lhs.seekableTintColor == rhs.seekableTintColor &&
             lhs.thumbImageColor == rhs.thumbImageColor &&
             lhs.thumbnailBorderColor == rhs.thumbnailBorderColor &&
             lhs.thumbnailTimeCodeColor == rhs.thumbnailTimeCodeColor
     }
}

struct TimeCodesHashableProps : Hashable {
  var currentTimeColor: UIColor
  var durationColor: UIColor
  
  init(currentTimeColor: UIColor, durationColor: UIColor) {
    self.currentTimeColor = currentTimeColor
    self.durationColor = durationColor
  }
  
  init(dictionary: NSDictionary?) {
    self.currentTimeColor = transformStringIntoUIColor(color: dictionary?["currentTimeColor"] as? String)
    self.durationColor = transformStringIntoUIColor(color: dictionary?["durationColor"] as? String)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(currentTimeColor)
    hasher.combine(durationColor)
  }
  
  static func == (lhs: TimeCodesHashableProps, rhs: TimeCodesHashableProps) -> Bool {
    return lhs.currentTimeColor == rhs.currentTimeColor && lhs.durationColor == rhs.durationColor
  }
}
///-----

struct HashableControllers: Hashable {
  var playbackControl: PlaybackControlHashableProps
  var seekSliderControl: SeekSliderControlHashableProps
  var timeCodesControl: TimeCodesHashableProps
  
  init(playbackControl: PlaybackControlHashableProps, seekSliderControl: SeekSliderControlHashableProps, timeCodesControl: TimeCodesHashableProps) {
    self.playbackControl = playbackControl
    self.seekSliderControl = seekSliderControl
    self.timeCodesControl = timeCodesControl
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(playbackControl)
    hasher.combine(seekSliderControl)
    hasher.combine(timeCodesControl)
  }
  
  static func == (lhs: HashableControllers, rhs: HashableControllers) -> Bool {
    return lhs.playbackControl == rhs.playbackControl && lhs.seekSliderControl == rhs.seekSliderControl && lhs.timeCodesControl == rhs.timeCodesControl
  }
}
