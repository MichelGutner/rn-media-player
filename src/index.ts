import { Platform, UIManager, requireNativeComponent } from 'react-native';
import type { TVideoPlayerProps } from './types';
export { EResizeMode } from './types';
export type { TVideoPlayerProps } from './types';

const LINKING_ERROR =
  "The package 'rn-media-player' doesn't seem to be linked. Make sure: \n\n" +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n';

const ComponentName = 'RNVideoPlayer';

export const Video =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<TVideoPlayerProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };