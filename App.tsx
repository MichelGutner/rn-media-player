/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, {useState, useEffect} from 'react';
import {
  requireNativeComponent,
  useWindowDimensions,
  View,
  Button,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
} from 'react-native';
import {PlayPauseIcon} from './src/components/PlayButton';
const VPlayer = requireNativeComponent('RNVideoPlayer');

function App(): JSX.Element {
  const {width, height} = useWindowDimensions();
  const [pause, setPause] = useState(false);
  const [rate, setRate] = useState(1);
  const [currentTime, setCurrentTime] = useState(0);
  const [loadData, setLoadData] = useState<any>();
  const [isFullScreen, setFullScreen] = useState(false);

  // useEffect(() => {
  //   setTimeout(() => {
  //     setFullScreen(!isFullScreen);
  //   }, 6000);
  // }, [isFullScreen]);

  return (
    <>
      <VPlayer
        style={{...StyleSheet.absoluteFillObject}}
        source="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
        // source="https://assets.mixkit.co/videos/download/mixkit-countryside-meadow-4075.mp4"
        autoPlay={true}
        paused={pause}
        rate={rate}
        resizeMode="contain"
        onLoaded={({nativeEvent}) => setLoadData(nativeEvent)}
        onVideoProgress={data => setCurrentTime(data.nativeEvent.progress)}
        onCompleted={({nativeEvent: {completed}}) => console.log(completed)}
        fullScreen={isFullScreen}
        timeValueForChange={10}
        sliderProps={{
          maximumTrackColor: '#f2f2f2',
          minimumTrackColor: '#3939ae',
          thumbSize: 20,
          thumbColor: '#412cdf',
        }}
      />
      {/* <View
        style={{
          ...StyleSheet.absoluteFillObject,
          backgroundColor: 'transparent',
          alignItems: 'center',
          justifyContent: 'center',
        }}
        // onPress={() => setPause(!pause)}
        // activeOpacity={0.8}
        hitSlop={{top: 10, bottom: 10, left: 10, right: 10}}>
        <PlayPauseIcon />
      </View> */}
    </>
  );
}

export default App;
