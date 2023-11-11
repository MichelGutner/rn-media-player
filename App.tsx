/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, {useState} from 'react';
import {
  StyleSheet,
  requireNativeComponent,
  useColorScheme,
  ViewStyle,
  useWindowDimensions,
} from 'react-native';
const VPlayer = requireNativeComponent('RNVideoPlayer');
import {Colors} from 'react-native/Libraries/NewAppScreen';

function App(): JSX.Element {
  const {width, height} = useWindowDimensions();
  const isDarkMode = useColorScheme() === 'dark';
  const [pause, setPause] = useState(false);
  const [rate, setRate] = useState(1);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);

  const backgroundStyle: ViewStyle = {
    flex: 1,
  };

  return (
    <VPlayer
      style={{
        height,
        width,
      }}
      source="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
      autoPlay={true}
      paused={pause}
      rate={rate}
      onLoaded={({nativeEvent: {loaded}}) => console.log(loaded)}
      onVideoProgress={data => setCurrentTime(data.nativeEvent.progress)}
      onVideoDuration={data => setDuration(data.nativeEvent.videoDuration)}
      onCompleted={({nativeEvent: {completed}}) => console.log(completed)}
    />
  );
}

const styles = StyleSheet.create({
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
  },
  highlight: {
    fontWeight: '700',
  },
});

export default App;
