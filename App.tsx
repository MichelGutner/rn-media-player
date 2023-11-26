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
    <View style={{height: 350, backgroundColor: 'white'}}>
      <VPlayer
        style={{...StyleSheet.absoluteFillObject}}
        source="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
        // source="https://assets.mixkit.co/videos/download/mixkit-countryside-meadow-4075.mp4"
        paused={pause}
        rate={rate}
        resizeMode="contain"
        onLoaded={({nativeEvent}) => setLoadData(nativeEvent)}
        onVideoProgress={data => setCurrentTime(data.nativeEvent.progress)}
        onCompleted={({nativeEvent: {completed}}) => console.log(completed)}
        onDeviceOrientation={({nativeEvent: {isPortrait}}) =>
          console.log(isPortrait)
        }
        fullScreen={isFullScreen}
        timeValueForChange={10}
        sliderProps={{
          maximumTrackColor: '#fff2f2',
          minimumTrackColor: '#3939ae',
          thumbSize: 10,
          thumbColor: '#412cdf',
        }}
      />
      <Button title="Pause" onPress={() => setPause(!pause)} />
    </View>
  );
}

export default App;
