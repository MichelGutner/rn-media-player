//
//  RNVideoPlayerManager.m
//  RNVideoPlayer
//
//  Created by Michel on 30/10/23.
//

#import <React/RCTBridge.h>
#import "React/RCTViewManager.h"

@interface RCT_EXTERN_MODULE(RNVideoPlayer, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(source, NSString);
RCT_EXPORT_VIEW_PROPERTY(paused, BOOL);
RCT_EXPORT_VIEW_PROPERTY(rate, float)
RCT_EXPORT_VIEW_PROPERTY(onVideoProgress, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoaded, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onCompleted, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(fullScreen, BOOL)
RCT_EXPORT_VIEW_PROPERTY(timeValueForChange, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(onMoreOptionsTapped, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFullScreenTapped, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onGoBackTapped, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onReady, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBufferCompleted, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBuffer, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(videoTitle, NSString)
RCT_EXPORT_VIEW_PROPERTY(resizeMode, NSString)

RCT_EXPORT_VIEW_PROPERTY(sliderProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(forwardProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(backwardProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(playPauseProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(labelDurationProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(labelProgressProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(menuOptionsProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(fullScreenProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(titleProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(goBackProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(menuOptionsItemProps, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(loadingProps, NSDictionary)

@end
