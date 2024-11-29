import type { ViewProps, ViewStyle } from 'react-native';
import type {
  WithDefault,
  DirectEventHandler,
  Float,
} from 'react-native/Libraries/Types/CodegenTypes';

export const enum EResizeMode {
  Cover = 'cover',
  Contain = 'contain',
  Stretch = 'stretch',
}

type ResizeMode = WithDefault<
  EResizeMode | 'cover' | 'contain' | 'stretch',
  'none'
>;

type TVideoPlayerControlConfig = {
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
    durationColor?: string;
  };
  fullScreen?: {
    color?: string;
  };
  menus?: {
    color?: string;
  };
};

type TOnError = TGenericEventHandler<{
  code: number;
  userInfo: {
    description: string;
    failureReason: string;
    fixSuggestion: string;
  };
}>;

type TOnVideoProgress = TGenericEventHandler<{
  buffering: Float;
  progress: Float;
}>;

type TOnFullscreen = TGenericEventHandler<{
  isFullscreen: boolean;
}>;

type TOnVideoBuffer = TGenericEventHandler<{
  buffering: boolean;
  completed: boolean;
  empty: boolean;
}>;

type TOnVideoCompleted = TGenericEventHandler<{ completed: boolean }>;
type TOnVideoPlayPause = TGenericEventHandler<{ isPlaying: boolean }>;
type TOnMediaRouter = TGenericEventHandler<{ isActive: boolean }>;
type TonPinchZoom = TGenericEventHandler<{ currentZoom: string }>;
type TOnSeekBar = TGenericEventHandler<{
  start: {
    percent: Float;
    seconds: Float;
  };
  ended: {
    percent: Float;
    seconds: Float;
  };
}>;
type TOnReady = TGenericEventHandler<{
  duration: Float;
  loaded: boolean;
}>;
type TOnVideoBufferCompleted = TGenericEventHandler<{
  completed: boolean;
}>;

export type TVideoPlayer = Omit<ViewProps, 'style'> & {
  source: {
    url: string;
    startTime?: number;
    metadata: {
      title?: string;
      artist?: string;
    };
    thumbnails?: {
      url: string;
      enabled?: boolean;
    };
  };
  thumbnailFramesSeconds?: number;
  screenBehavior?: {
    autoEnterFullscreenOnLandscape?: boolean;
    autoOrientationOnFullscreen?: boolean;
  };
  autoPlay?: boolean;
  style?: ViewStyle;
  rate?: number;
  startTime?: number;
  resizeMode?: ResizeMode;
  // lockControls?: boolean;
  tapToSeek?: {
    value: number;
    suffixLabel: string;
  };
  /**
   * Set this parameter to change the quality of the video
   */
  changeQualityUrl?: string;
  controlsStyles?: TVideoPlayerControlConfig;
  /**
   * iOS only
   */
  onBufferCompleted?: TOnVideoBufferCompleted;
  onFullscreen?: TOnFullscreen;
  onBuffer?: TOnVideoBuffer;
  onReady?: TOnReady;
  onVideoProgress?: TOnVideoProgress;
  onPlayPause?: TOnVideoPlayPause;
  onCompleted?: TOnVideoCompleted;
  onMediaRouter?: TOnMediaRouter;
  onSeekBar?: TOnSeekBar;
  onPinchZoom?: TonPinchZoom;
  onError?: TOnError;
  menus?: {
    [key: string]: {
      readonly data: { name: string; value: unknown }[];
      readonly initialItemSelected: string;
    };
  };
  /**
   * Get menu item selected on settings
   */
  onMenuItemSelected?: TGenericEventHandler<{ name: string; value: any }>;
};

type TGenericEventHandler<T> = DirectEventHandler<Readonly<T>>;
