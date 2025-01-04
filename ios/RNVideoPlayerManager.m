//
//  RNVideoPlayerManager.m
//  RNVideoPlayer
//
//  Created by Michel on 30/10/23.
//
#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(RNVideoPlayer, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(source, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(controlsStyles, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(tapToSeek, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(screenBehavior, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(thumbnails, NSDictionary)

RCT_EXPORT_VIEW_PROPERTY(paused, BOOL);
RCT_EXPORT_VIEW_PROPERTY(autoPlay, BOOL)
RCT_EXPORT_VIEW_PROPERTY(entersFullScreenWhenPlaybackBegins, BOOL)
RCT_EXPORT_VIEW_PROPERTY(rate, float)


RCT_EXPORT_VIEW_PROPERTY(resizeMode, NSString)
RCT_EXPORT_VIEW_PROPERTY(replaceMediaUrl, NSString)


RCT_EXPORT_VIEW_PROPERTY(onMediaBuffering, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMediaCompleted, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFullScreenStateChanged, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMediaError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMediaReady, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMediaBufferCompleted, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMediaPlayPause, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMediaRouter, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMediaSeekBar, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMediaPinchZoom, RCTDirectEventBlock)

RCT_EXPORT_VIEW_PROPERTY(menus, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(onMenuItemSelected, RCTBubblingEventBlock)

@end
