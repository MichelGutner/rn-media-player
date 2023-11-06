/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, {useState} from 'react';
import {
  SafeAreaView,
  StyleSheet,
  requireNativeComponent,
  useColorScheme,
  Button,
} from 'react-native';
const VPlayer = requireNativeComponent('RNVideoPlayer');
import {Colors} from 'react-native/Libraries/NewAppScreen';

function App(): JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
  const [pause, setPause] = useState(false);
  const [rate, setRate] = useState(1);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  return (
    <SafeAreaView style={backgroundStyle}>
      <VPlayer
        style={{
          height: 300,
        }}
        source="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"
        autoPlay={true}
        paused={pause}
        rate={rate}
        onLoaded={({nativeEvent: {loaded}}) => console.log(loaded)}
        seek={10}
        onVideoProgress={data => setCurrentTime(data.nativeEvent.progress)}
        getVideoDuration={data => setDuration(data.nativeEvent.duration)}
        onCompleted={({nativeEvent: {completed}}) => console.log(completed)}
      />
      <Button
        title={pause ? 'Play' : `Pause ${currentTime}`}
        onPress={() => setPause(!pause)}
      />
      <Button
        title={`Change Rate (currente: ${rate})`}
        onPress={() => {
          if (rate === 1) {
            setRate(2);
          } else {
            setRate(1);
          }
        }}
      />
    </SafeAreaView>
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
