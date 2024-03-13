//
//  RNVideoPlayerManager.m
//  RNVideoPlayer
//
//  Created by Michel on 30/10/23.
//

#import <React/RCTBridge.h>
#import "React/RCTViewManager.h"

@interface RCT_EXTERN_MODULE(RNVideoPlayer, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(source, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(paused, BOOL);
RCT_EXPORT_VIEW_PROPERTY(rate, float)
RCT_EXPORT_VIEW_PROPERTY(startTime, float)
RCT_EXPORT_VIEW_PROPERTY(thumbnailFramesSeconds, float)
//RCT_EXPORT_VIEW_PROPERTY(fullScreen, BOOL)
RCT_EXPORT_VIEW_PROPERTY(enterInFullScreenWhenDeviceRotated, BOOL)
RCT_EXPORT_VIEW_PROPERTY(autoPlay, BOOL)
RCT_EXPORT_VIEW_PROPERTY(loop, BOOL)
RCT_EXPORT_VIEW_PROPERTY(videoTitle, NSString)
RCT_EXPORT_VIEW_PROPERTY(resizeMode, NSString)
RCT_EXPORT_VIEW_PROPERTY(doubleTapSeekValue, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(suffixLabelDoubleTapSeek, NSString)


RCT_EXPORT_VIEW_PROPERTY(onVideoProgress, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoaded, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onCompleted, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onSettingsTapped, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFullScreenTapped, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onGoBackTapped, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onReady, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBufferCompleted, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBuffer, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoDownloaded, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onDownloadVideoTapped, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPlaybackSpeedTapped, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onQualityTapped, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPlayPause, RCTDirectEventBlock)

RCT_EXPORT_VIEW_PROPERTY(sliderProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(forwardProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(backwardProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(playPauseProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(labelDurationProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(labelProgressProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(fullScreenProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(titleProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(goBackProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(loadingProps, NSDictionary)

// -- Settings Options data
RCT_EXPORT_VIEW_PROPERTY(speeds, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(qualities, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(settings, NSDictionary)

@end
