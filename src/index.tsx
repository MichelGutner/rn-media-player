import React from 'react';
import { Platform, UIManager, requireNativeComponent } from 'react-native';
import type { VideoPlayer } from './types';
import { setDefaultConfigs } from './helpers';
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
  const configs = setDefaultConfigs(props);
  return <VideoPlayer {...configs} />;
};
