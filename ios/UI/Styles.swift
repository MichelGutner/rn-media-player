//
//  ControllersProps.swift
//  RNVideoPlayer
//
//  Created by Michel Gutner on 13/03/24.
//

struct PlaybackControlsStyle: Hashable {
  var color: UIColor?
  
  init(color: UIColor) {
    self.color = color
  }
  
  init(dictionary: NSDictionary?) {
    self.color = transformStringIntoUIColor(color: dictionary?["color"] as? String)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(color)
  }
  
  static func == (lhs: PlaybackControlsStyle, rhs: PlaybackControlsStyle) -> Bool {
    return lhs.color == rhs.color
  }
}

struct SeekSliderStyle : Hashable {
  var maximumTrackColor: UIColor?
  var minimumTrackColor: UIColor?
  var seekableTintColor: UIColor?
  var thumbImageColor: UIColor?
  var thumbnailBorderColor: UIColor?
  var thumbnailTimeCodeColor: UIColor?
  
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
  
  static func == (lhs: SeekSliderStyle, rhs: SeekSliderStyle) -> Bool {
    return lhs.maximumTrackColor == rhs.maximumTrackColor &&
    lhs.minimumTrackColor == rhs.minimumTrackColor &&
    lhs.seekableTintColor == rhs.seekableTintColor &&
    lhs.thumbImageColor == rhs.thumbImageColor &&
    lhs.thumbnailBorderColor == rhs.thumbnailBorderColor &&
    lhs.thumbnailTimeCodeColor == rhs.thumbnailTimeCodeColor
  }
}

struct TimeCodesStyle : Hashable {
  var currentTimeColor: UIColor?
  var durationColor: UIColor?
  var slashColor: UIColor?
  
  init(currentTimeColor: UIColor, durationColor: UIColor, slashColor: UIColor) {
    self.currentTimeColor = currentTimeColor
    self.durationColor = durationColor
    self.slashColor = slashColor
  }
  
  init(dictionary: NSDictionary?) {
    self.currentTimeColor = transformStringIntoUIColor(color: dictionary?["currentTimeColor"] as? String)
    self.durationColor = transformStringIntoUIColor(color: dictionary?["durationColor"] as? String)
    self.slashColor = transformStringIntoUIColor(color: dictionary?["slashColor"] as? String)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(currentTimeColor)
    hasher.combine(durationColor)
    hasher.combine(slashColor)
  }
  
  static func == (lhs: TimeCodesStyle, rhs: TimeCodesStyle) -> Bool {
    return lhs.currentTimeColor == rhs.currentTimeColor && lhs.durationColor == rhs.durationColor && lhs.slashColor == rhs.slashColor
  }
}

struct MenusStyle: Hashable {
  var color: UIColor?
  
  init(color: UIColor) {
    self.color = color
  }
  
  init(dictionary: NSDictionary?) {
    self.color = transformStringIntoUIColor(color: dictionary?["color"] as? String)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(color)
  }
  
  static func == (lhs: MenusStyle, rhs: MenusStyle) -> Bool {
    return lhs.color == rhs.color
  }
}

struct FullScreenButtonStyle: Hashable {
  var color: UIColor?
  
  init(color: UIColor) {
    self.color = color
  }
  
  init(dictionary: NSDictionary?) {
    self.color = transformStringIntoUIColor(color: dictionary?["color"] as? String)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(color)
  }
  
  static func == (lhs: FullScreenButtonStyle, rhs: FullScreenButtonStyle) -> Bool {
    return lhs.color == rhs.color
  }
}

struct HeaderStyle: Hashable {
  var leftButtonColor: UIColor?
  var titleColor: UIColor?
  
  
  init(leftButtonColor: UIColor? = nil, titleColor: UIColor? = nil) {
    self.leftButtonColor = leftButtonColor
    self.titleColor = titleColor
  }
  
  init(dictionary: NSDictionary?) {
    self.leftButtonColor = transformStringIntoUIColor(color: dictionary?["leftButtonColor"] as? String)
    self.titleColor = transformStringIntoUIColor(color: dictionary?["titleColor"] as? String)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(leftButtonColor)
    hasher.combine(titleColor)
  }

  static func == (lhs: HeaderStyle, rhs: HeaderStyle) -> Bool {
    return lhs.leftButtonColor == rhs.leftButtonColor && lhs.titleColor == rhs.titleColor
  }
}

struct DownloadControlHashableProps: Hashable {
  var color: UIColor?
  var progressBarFillColor: UIColor?
  var progressBarColor: UIColor?
  var messageDelete: String?
  var messageDownload: String?
  var labelDelete: String?
  var labelCancel: String?
  var labelDownload: String?
  
  init(color: UIColor, progressBarFillColor: UIColor, progressBarColor: UIColor, messageDelete: String? = nil, messageDownload: String? = nil, labelDelete: String? = nil, labelCancel: String? = nil, labelDownload: String? = nil) {
    self.color = color
    self.progressBarFillColor = progressBarFillColor
    self.progressBarColor = progressBarColor
    self.messageDelete = messageDelete
    self.messageDownload = messageDownload
    self.labelDelete = labelDelete
    self.labelCancel = labelCancel
    self.labelDownload = labelDownload
  }
  
  init(dictionary: NSDictionary?) {
    self.color = transformStringIntoUIColor(color: dictionary?["color"] as? String)
    self.progressBarFillColor = transformStringIntoUIColor(color: dictionary?["progressBarFillColor"] as? String)
    self.progressBarColor = transformStringIntoUIColor(color: dictionary?["progressBarColor"] as? String)
    self.messageDelete = dictionary?["messageDelete"] as? String
    self.messageDownload = dictionary?["messageDownload"] as? String
    self.labelCancel = dictionary?["labelCancel"] as? String
    self.labelDelete = dictionary?["labelDelete"] as? String
    self.labelDownload = dictionary?["labelDownload"] as? String
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(color)
    hasher.combine(progressBarFillColor)
    hasher.combine(progressBarColor)
    hasher.combine(messageDelete)
    hasher.combine(messageDownload)
    hasher.combine(labelCancel)
    hasher.combine(labelDelete)
    hasher.combine(labelDownload)
  }
  
  static func == (lhs: DownloadControlHashableProps, rhs: DownloadControlHashableProps) -> Bool {
    return lhs.color == rhs.color &&
    lhs.progressBarFillColor == rhs.progressBarFillColor &&
    lhs.progressBarColor == rhs.progressBarColor &&
    lhs.messageDelete == rhs.messageDelete &&
    lhs.messageDownload == rhs.messageDownload &&
    lhs.labelCancel == rhs.labelCancel &&
    lhs.labelDelete == rhs.labelDelete &&
    lhs.labelDownload == rhs.labelDownload
  }
}

struct ToastStyle: Hashable {
  var label: String?
  var labelColor: UIColor?
  var backgroundColor: UIColor?
  
  init(label: String, labelColor: UIColor, backgroundColor: UIColor) {
    self.label = label
    self.labelColor = labelColor
    self.backgroundColor = backgroundColor
  }
  
  init(dictionary: NSDictionary?) {
    self.label = dictionary?["label"] as? String
    self.labelColor = transformStringIntoUIColor(color: dictionary?["labelColor"] as? String)
    self.backgroundColor = transformStringIntoUIColor(color: dictionary?["backgroundColor"] as? String)
  }
  
  
  static func == (lhs: ToastStyle, rhs: ToastStyle) -> Bool {
    return lhs.label == rhs.label && lhs.labelColor == rhs.labelColor && lhs.backgroundColor == rhs.backgroundColor
  }
}

struct LoadingStyle: Hashable {
  var color: UIColor?
  
  init(color: UIColor) {
    self.color = color
  }
  
  init(dictionary: NSDictionary?) {
    self.color = transformStringIntoUIColor(color: dictionary?["color"] as? String)
  }
  
  
  static func == (lhs: LoadingStyle, rhs: LoadingStyle) -> Bool {
    return lhs.color == rhs.color
  }
}

///----- 

struct Styles: Hashable {
  var playback: PlaybackControlsStyle
  var seekSlider: SeekSliderStyle
  var timeCodes: TimeCodesStyle
  var menus: MenusStyle
  var fullScreen: FullScreenButtonStyle
  var download: DownloadControlHashableProps
  var toast: ToastStyle
  var header: HeaderStyle
  var loading: LoadingStyle
  
  init(
    playbackControl: PlaybackControlsStyle,
    seekSliderControl: SeekSliderStyle,
    timeCodesControl: TimeCodesStyle,
    menusControl: MenusStyle,
    fullScreenControl: FullScreenButtonStyle,
    downloadControl: DownloadControlHashableProps,
    toastControl: ToastStyle,
    headerControl: HeaderStyle,
    loadingControl: LoadingStyle
  ) {
    self.playback = playbackControl
    self.seekSlider = seekSliderControl
    self.timeCodes = timeCodesControl
    self.menus = menusControl
    self.fullScreen = fullScreenControl
    self.download = downloadControl
    self.toast = toastControl
    self.header = headerControl
    self.loading = loadingControl
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(playback)
    hasher.combine(seekSlider)
    hasher.combine(timeCodes)
    hasher.combine(menus)
    hasher.combine(fullScreen)
    hasher.combine(download)
    hasher.combine(toast)
    hasher.combine(header)
    hasher.combine(loading)
  }
  
  static func == (lhs: Styles, rhs: Styles) -> Bool {
    return lhs.playback == rhs.playback && lhs.seekSlider == rhs.seekSlider && lhs.timeCodes == rhs.timeCodes && lhs.menus == rhs.menus && lhs.fullScreen == rhs.fullScreen && lhs.download == rhs.download && lhs.toast == rhs.toast && lhs.header == rhs.header && lhs.loading == rhs.loading
  }
}
