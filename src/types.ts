import type { ViewProps, ViewStyle } from 'react-native';
import type {
  DirectEventHandler,
  Float,
} from 'react-native/Libraries/Types/CodegenTypes';

export const enum EResizeMode {
  Cover = 'cover',
  Contain = 'contain',
  Stretch = 'stretch',
}

// type ResizeMode = WithDefault<
//   EResizeMode | 'cover' | 'contain' | 'stretch',
//   'none'
// >;

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

type TOnMediaBuffering = TGenericEventHandler<{
  totalBuffered: Float;
  progress: Float;
}>;

type TOnFullscreen = TGenericEventHandler<{
  isFullscreen: boolean;
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

export type VideoPlayer = Omit<ViewProps, 'style'> & {
  source: {
    url: string;
    metadata?: {
      title?: string;
      artist?: string;
    };
    startTime?: number;
  };
  thumbnails?: {
    sourceUrl: string;
    isEnabled?: boolean;
    // framesPerSecond?: number;
  };
  entersFullScreenWhenPlaybackBegins?: boolean;
  autoPlay?: boolean;
  style?: ViewStyle;
  rate?: number;
  // lockControls?: boolean;
  doubleTapToSeek?: {
    value: number;
    suffixLabel: string;
  };
  controlsStyles?: TVideoPlayerControlConfig;
  onMediaBufferCompleted?: TOnVideoBufferCompleted;
  onFullScreenStateChanged?: TOnFullscreen;
  onMediaReady?: TOnReady;
  onMediaBuffering?: TOnMediaBuffering;
  onMediaPlayPause?: TOnVideoPlayPause;
  onMediaCompleted?: TOnVideoCompleted;
  onMediaSeekBar?: TOnSeekBar;
  onMediaPinchZoom?: TonPinchZoom;
  onMediaError?: TOnError;
  onMenuItemSelected?: TGenericEventHandler<{ name: string; value: any }>;
  menuOptions: {
    qualities: TMenuOptions;
    speeds: TMenuOptions;
    captions: {
      title?: string;
      disabledCaptionName?: string;
      disabled?: boolean;
    };
  };
  /**
   * iOS only
   */
  onMediaRouter?: TOnMediaRouter;
  playList?: TPlayList[];
};

type TMenuOptions = {
  title?: string;
  options: { name: string; value: unknown }[];
  initialOptionSelected: string;
  disabled?: boolean;
};

type TGenericEventHandler<T> = DirectEventHandler<Readonly<T>>;

type TPlayList = {
  title: string;
  thumbUrl: string;
  url: string;
  startTime: number;
};
