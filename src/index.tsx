/* eslint-disable react-native/no-inline-styles */
import React from 'react';
import {
  Platform,
  UIManager,
  requireNativeComponent,
  useWindowDimensions,
} from 'react-native';
import type { TVideoPlayerProps } from './types';
import { ensureHttpsUrl } from './helpers';
import { defaultSettings } from './constants';
export { EResizeMode } from './types';
export type { TVideoPlayerProps } from './types';

const LINKING_ERROR =
  "The package 'rn-media-player' doesn't seem to be linked. Make sure: \n\n" +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n';

const ComponentName = 'RNVideoPlayer';

const VideoPlayer =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<TVideoPlayerProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };

export const Video = (props: TVideoPlayerProps) => {
  const { height, width } = useWindowDimensions();
  const url = ensureHttpsUrl(props.source.url);
  console.log('🚀 ~ Video ~ url:', url);
  return (
    <VideoPlayer
      settings={defaultSettings}
      {...props}
      style={{ height, width, ...props?.style, overflow: 'hidden' }}
      source={{ url, title: props.source.title }}
    />
  );
};
