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
RCT_EXPORT_VIEW_PROPERTY(onTapSettingsControl, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFullScreen, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onGoBack, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onReady, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBufferCompleted, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBuffer, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoDownloaded, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onDownloadVideo, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPlaybackSpeed, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onQuality, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPlayPause, RCTDirectEventBlock)

RCT_EXPORT_VIEW_PROPERTY(controlsProps, NSDictionary)

// -- Settings Options data
RCT_EXPORT_VIEW_PROPERTY(speeds, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(qualities, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(settings, NSDictionary)

@end
