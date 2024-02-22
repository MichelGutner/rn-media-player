/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, {useState} from 'react';
import {SafeAreaView, useWindowDimensions} from 'react-native';
import {RNPlayerVideo} from './src/player';

function App(): JSX.Element {
  const {height} = useWindowDimensions();
  const [isFull, setIsFull] = useState(true);

  // useEffect(() => {
  //   setTimeout(() => {
  //     setIsFull(!isFull);
  //   }, 12000);
  // }, [isFull]);
  const resizeMode = isFull ? 'cover' : 'contain';
  return (
    <RNPlayerVideo
      isFullScreen={isFull}
      // style={{height}}
      style={{height: isFull ? height : 350, zIndex: 2}}
      onFullScreen={() => setIsFull(!isFull)}
      resizeMode={resizeMode}
      paused={false}
      startTime={50}
    />
  );
}

export default App;
