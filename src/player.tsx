/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, {useState} from 'react';
import {
  StyleSheet,
  View,
  ViewStyle,
  requireNativeComponent,
  useWindowDimensions,
} from 'react-native';
const VPlayer = requireNativeComponent<{
  style: ViewStyle;
  sliderProps: {maximumTrackColor: string};
  forwardProps: TAdvanceVideoControlProps<'forward'>;
  backwardProps: TAdvanceVideoControlProps<'backward'>;
}>('RNVideoPlayer');

export type TAdvanceVideoControlProps<T extends TImageTypes> = {
  color?: string;
  hidden?: boolean;
  image?: TImageControlProps<T>;
};

type TImageTypes = 'forward' | 'backward';

type TImageControlProps<T extends TImageTypes> =
  | `${T}empty`
  | `${T}15`
  | `${T}30`
  | `${T}45`
  | `${T}60`
  | `${T}75`
  | `${T}90`
  | `${T}Default`;

export const RNPlayerVideo = ({
  style,
  isFullScreen,
  onFullScreen,
  resizeMode,
  loading,
}: {
  style: ViewStyle;
  isFullScreen: boolean;
  onFullScreen: () => void;
  loading: boolean;
}): JSX.Element => {
  const {width, height} = useWindowDimensions();
  const [pause, setPause] = useState(false);
  const [rate, setRate] = useState(1);
  const [currentTime, setCurrentTime] = useState(undefined);
  const [loadData, setLoadData] = useState<any>();

  return (
    <View style={style}>
      <VPlayer
        style={
          {...StyleSheet.absoluteFillObject, overflow: 'hidden'} as ViewStyle
        }
        source="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
        // source="https://assets.mixkit.co/videos/download/mixkit-countryside-meadow-4075.mp4"
        paused={pause}
        rate={rate}
        videoTitle={'Game of Thrones'}
        onLoaded={({nativeEvent}) => setLoadData(nativeEvent)}
        onVideoProgress={data => setCurrentTime(data.nativeEvent)}
        onCompleted={({nativeEvent: {completed}}) => console.log(completed)}
        fullScreen={isFullScreen}
        resizeMode={resizeMode}
        timeValueForChange={10}
        lockControls={true}
        onError={e => console.log(e.nativeEvent.error)}
        sliderProps={{
          maximumTrackColor: '#dd1212',
          minimumTrackColor: '#3939ae',
          thumbSize: 10,
          thumbColor: '#412cdf',
        }}
        onMoreOptionsTapped={() => console.log('MORE OPTIONS TAPPED')}
        onFullScreenTapped={onFullScreen}
        onGoBackTapped={() => console.log('GO BACK TAPPED')}
        onBufferCompleted={e =>
          console.log(`BUFFER COMPLETED ${JSON.stringify(e.nativeEvent)}`)
        }
        onBuffer={
          e => undefined
          // console.log(`BUFFER STARTED ${JSON.stringify(e.nativeEvent)}`)
        }
        // disableNativeControls={{
        //   disableSeek: true,
        //   disableVolume: true,
        //   disableFullScreen: true,
        //   disableMoreOptions: true,
        // }}
        // loading={loading}
      />
    </View>
  );
};
