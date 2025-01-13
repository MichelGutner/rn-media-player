/* eslint-disable react-native/no-inline-styles */
import React from 'react';
import { Platform, UIManager, requireNativeComponent } from 'react-native';
import type { VideoPlayer } from './types';
export { EResizeMode } from './types';
export type { VideoPlayer as TVideoPlayerProps } from './types';

const LINKING_ERROR =
  "The package 'rn-media-player' doesn't seem to be linked. Make sure: \n\n" +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n';

const ComponentName = 'RNVideoPlayer';

const VideoPlayer =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<VideoPlayer>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };

export const Video = (props: VideoPlayer) => {
  return (
    <VideoPlayer {...props} style={{ ...props?.style, overflow: 'hidden' }} />
  );
};
