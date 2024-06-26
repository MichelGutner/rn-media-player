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

type TOptionProperties = {
  initialSelected: string;
  data: ReadonlyArray<{
    name: string;
    value: string;
    enabled: boolean;
  }>;
};

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

type TOnError = TGenericEventHandler<{
  code: number;
  userInfo: string;
  description: string;
  failureReason: string;
  fixSuggestion: string;
}>;
type TOnVideoProgress = TGenericEventHandler<{
  buffering: Float;
  progress: Float;
}>;
type TOnVideoDownloaded = TGenericEventHandler<{
  downloaded: boolean;
  status: string;
  error: any;
}>;
type TOnVideoBuffer = TGenericEventHandler<{ buffering: boolean }>;
type TOnVideoCompleted = TGenericEventHandler<{ completed: boolean }>;
type TOnVideoPlayPause = TGenericEventHandler<{ isPlaying: boolean }>;
type TOnVideoLoaded = TGenericEventHandler<{ duration: Float }>;
type TOnVideoFullScreen = TGenericEventHandler<{ fullScreen: boolean }>;
type TOnVideoBufferCompleted = TGenericEventHandler<{
  completed: boolean;
}>;

export type TVideoPlayerProps = Omit<ViewProps, 'style'> & {
  source: {
    url: string;
    title?: string;
  };
  thumbnailFramesSeconds?: number;
  enterInFullScreenWhenDeviceRotated?: boolean;
  autoPlay?: boolean;
  loop?: boolean;
  style?: ViewStyle;
  paused?: boolean;
  rate?: number;
  startTime?: number;
  resizeMode?: ResizeMode;
  // lockControls?: boolean;
  tapToSeekValue?: number;
  suffixLabelTapToSeek?: string;
  speeds?: TOptionProperties;
  qualities?: TOptionProperties;
  settings?: Omit<TOptionProperties, 'initialSelected'>;
  controlsProps?: TVideoPlayerControlConfig;
  onSettings?: () => void;
  onGoBack?: () => void;
  onPlaybackSpeed?: () => void;
  onQuality?: () => void;
  onFullScreen?: TOnVideoFullScreen;
  onBufferCompleted?: TOnVideoBufferCompleted;
  onVideoDownloaded?: TOnVideoDownloaded;
  onBuffer?: TOnVideoBuffer;
  onLoaded?: TOnVideoLoaded;
  onVideoProgress?: TOnVideoProgress;
  onPlayPause?: TOnVideoPlayPause;
  onCompleted?: TOnVideoCompleted;
  onError?: TOnError;
};

type TGenericEventHandler<T> = DirectEventHandler<Readonly<T>>;
