/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, {useState} from 'react';
import {
  requireNativeComponent,
  useWindowDimensions,
  View,
  Button,
  StyleSheet,
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
  const test = secondsToHMS(loadData?.duration);

  const styles = {
    width: width,
    height: isFullScreen ? height : 350,
    backgroundColor: '#000',
  };
  const currentSlider = secondsToHMS(currentTime);

  // useEffect(() => {
  //   setTimeout(() => {
  //     setFullScreen(!fullScreen);
  //   }, 10000);
  // }, [fullScreen]);

  return (
    <>
      <View style={{...styles}}>
        <VPlayer
          style={{...StyleSheet.absoluteFillObject}}
          source="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
          autoPlay={true}
          paused={false}
          rate={rate}
          resizeMode="contain"
          onLoaded={({nativeEvent}) => setLoadData(nativeEvent)}
          onVideoProgress={data => setCurrentTime(data.nativeEvent.progress)}
          onCompleted={({nativeEvent: {completed}}) => console.log(completed)}
          fullScreen={isFullScreen}
        />
      </View>
      <View style={{flex: 1, position: 'absolute', top: 150, left: 150}}>
        <Button title="TEST" onPress={() => setRate(12)} />
      </View>
    </>
  );
}

export default App;

function secondsToHMS(durationInSeconds) {
  const hours = Math.floor(durationInSeconds / 3600);
  const minutes = Math.floor((durationInSeconds % 3600) / 60);
  const seconds = Math.round(durationInSeconds % 60);
  const hour = hours < 10 ? `0${hours}` : hours;
  const minute = minutes < 10 ? `0${minutes}` : minutes;
  const second = seconds < 10 ? `0${seconds}` : seconds;

  if (hours > 0) {
    return `${hour}:${minute}:${second}`;
  }
  return `${minute}:${second}`;
}
