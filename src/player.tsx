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
const VPlayer = requireNativeComponent('RNVideoPlayer');

export const RNPlayerVideo = ({
  style,
  isFullScreen,
  onFullScreen,
  resizeMode,
}: {
  style: ViewStyle;
  isFullScreen: boolean;
  onFullScreen: () => void;
}): JSX.Element => {
  const {width, height} = useWindowDimensions();
  const [pause, setPause] = useState(false);
  const [rate, setRate] = useState(1);
  const [currentTime, setCurrentTime] = useState(0);
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
        onVideoProgress={data => setCurrentTime(data.nativeEvent.progress)}
        onCompleted={({nativeEvent: {completed}}) => console.log(completed)}
        fullScreen={isFullScreen}
        resizeMode={resizeMode}
        onOrientationEvent={data =>
          console.log(
            data.nativeEvent.orientation === 'LANDSCAPE' ? true : false,
          )
        }
        timeValueForChange={10}
        onError={e => console.log(e.nativeEvent.error)}
        sliderProps={{
          maximumTrackColor: '#fff2f2',
          minimumTrackColor: '#3939ae',
          thumbSize: 10,
          thumbColor: '#412cdf',
        }}
        onMoreOptionsTapped={() => console.log('MORE OPTIONS TAPPED')}
        onFullScreenTapped={onFullScreen}
      />
    </View>
  );
};
