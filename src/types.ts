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
    startTime?: number;
    thumbnails?: {
      url: string;
      enableGenerate?: boolean;
    };
  };
  thumbnailFramesSeconds?: number;
  enterInFullScreenWhenDeviceRotated?: boolean;
  autoPlay?: boolean;
  style?: ViewStyle;
  paused?: boolean;
  rate?: number;
  startTime?: number;
  resizeMode?: ResizeMode;
  // lockControls?: boolean;
  tapToSeek: {
    value: number;
    suffixLabel: string;
  };
  /**
   * Set this parameter to change the quality of the video
   */
  changeQualityUrl?: string;
  controlsProps?: TVideoPlayerControlConfig;
  onSettings?: () => void;
  onFullScreen?: TOnVideoFullScreen;
  /**
   * iOS only
   */
  onBufferCompleted?: TOnVideoBufferCompleted;
  onVideoDownloaded?: TOnVideoDownloaded;
  onBuffer?: TOnVideoBuffer;
  onLoaded?: TOnVideoLoaded;
  onVideoProgress?: TOnVideoProgress;
  onPlayPause?: TOnVideoPlayPause;
  onCompleted?: TOnVideoCompleted;
  onError?: TOnError;
  menus: {
    [key: string]: unknown[];
  };
  /**
   * Get menu item selected on settings
   */
  onMenuItemSelected?: TGenericEventHandler<{ name: string; value: any }>;
};

type TGenericEventHandler<T> = DirectEventHandler<Readonly<T>>;
