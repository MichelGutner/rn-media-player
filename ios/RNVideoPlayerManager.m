//
//  RNVideoPlayerManager.m
//  RNVideoPlayer
//
//  Created by Michel on 30/10/23.
//
#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(RNVideoPlayer, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(source, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(controlsProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(tapToSeek, NSDictionary)

RCT_EXPORT_VIEW_PROPERTY(paused, BOOL);
RCT_EXPORT_VIEW_PROPERTY(autoPlay, BOOL)
RCT_EXPORT_VIEW_PROPERTY(enterInFullScreenWhenDeviceRotated, BOOL)

RCT_EXPORT_VIEW_PROPERTY(rate, float)
//RCT_EXPORT_VIEW_PROPERTY(thumbnailFramesSeconds, float)


RCT_EXPORT_VIEW_PROPERTY(resizeMode, NSString)
RCT_EXPORT_VIEW_PROPERTY(changeQualityUrl, NSString)


RCT_EXPORT_VIEW_PROPERTY(onVideoProgress, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoaded, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onCompleted, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onTapSettingsControl, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFullScreen, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onReady, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBufferCompleted, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBuffer, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPlayPause, RCTDirectEventBlock)

// -- Settings Options data
RCT_EXPORT_VIEW_PROPERTY(menus, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(onMenuItemSelected, RCTBubblingEventBlock)

@end
