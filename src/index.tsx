/* eslint-disable react-native/no-inline-styles */
import React from 'react';
import type {
  DirectEventHandler,
  Float,
  WithDefault,
} from 'react-native/Libraries/Types/CodegenTypes';
import {
  requireNativeComponent,
  UIManager,
  Platform,
  type ViewStyle,
  type ViewProps,
} from 'react-native';

const LINKING_ERROR =
  "The package 'rn-media-player' doesn't seem to be linked. Make sure: \n\n" +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

export const enum EResizeMode {
  Cover = 'cover',
  Contain = 'contain',
  Stretch = 'stretch',
}

type ResizeMode = WithDefault<
  EResizeMode | 'cover' | 'contain' | 'stretch',
  'none'
>;

type CommonDataSettingsProperties = {
  initialSelected: string;
  data: ReadonlyArray<{
    name: string;
    value: string;
    enabled: boolean;
  }>;
};

type VideoPlayerConfig = {
  loading?: {
    color?: string;
  };
  playback?: {
    color?: string;
  };
  seekSlider?: {
    maximumTrackColor?: string;
    minimumTrackColor?: string;
    seekableTintColor?: string;
    thumbImageColor?: string;
    thumbnailBorderColor?: string;
    thumbnailTimeCodeColor?: string;
  };
  timeCodes?: {
    currentTimeColor?: string;
    durationColor?: string;
    slashColor?: string;
  };
  settings?: {
    color?: string;
  };
  fullScreen?: {
    color?: string;
  };
  download?: {
    color?: string;
    progressBarColor?: string;
    progressBarFillColor?: string;
    messageDelete?: string;
    messageDownload?: string;
    labelDelete?: string;
    labelCancel?: string;
    labelDownload?: string;
  };
  toast?: {
    label?: string;
    backgroundColor?: string;
    labelColor?: string;
  };
  header?: {
    leftButtonColor?: string;
    titleColor?: string;
  };
};

type VideoPlayerProps = Omit<ViewProps, 'style'> & {
  source: {
    url: string;
    title: string;
  };
  thumbnailFramesSeconds?: number;
  enterInFullScreenWhenDeviceRotated?: boolean;
  autoPlay?: boolean;
  loop?: boolean;
  style?: ViewStyle;
  paused?: boolean;
  rate?: number;
  startTime?: number;
  onLoaded?: DirectEventHandler<Readonly<{ duration: Float }>>;
  onVideoProgress?: DirectEventHandler<
    Readonly<{ buffering: Float; progress: Float }>
  >;
  onPlayPause?: DirectEventHandler<Readonly<{ isPlaying: boolean }>>;
  onCompleted?: DirectEventHandler<Readonly<{ completed: boolean }>>;
  onError?: DirectEventHandler<
    Readonly<{
      code: number;
      userInfo: string;
      description: string;
      failureReason: string;
      fixSuggestion: string;
    }>
  >;
  resizeMode?: ResizeMode;
  lockControls?: boolean;
  doubleTapSeekValue?: number;
  suffixLabelDoubleTapSeek?: string;
  speeds?: CommonDataSettingsProperties;
  qualities?: CommonDataSettingsProperties;
  settings?: Omit<CommonDataSettingsProperties, 'initialSelected'>;
  controlsProps?: VideoPlayerConfig;
  onFullScreen?: DirectEventHandler<Readonly<{ fullScreen: boolean }>>;
  onSettings?: () => void;
  onGoBack?: () => void;
  onPlaybackSpeed?: () => void;
  onQuality?: () => void;
  onBufferCompleted?: DirectEventHandler<Readonly<{ completed: boolean }>>;
  onVideoDownloaded?: DirectEventHandler<
    Readonly<{ downloaded: boolean; status: string; error: any }>
  >;
  onBuffer?: DirectEventHandler<Readonly<{ buffering: boolean }>>;
};

const ComponentName = 'RNVideoPlayer';

export const VideoPlayer =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<VideoPlayerProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };

export const Video = (props: VideoPlayerProps) => (
  <VideoPlayer style={{ ...props?.style, overflow: 'hidden' }} {...props} />
);
