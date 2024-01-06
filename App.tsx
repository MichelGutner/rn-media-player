/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, {useState} from 'react';
import {useWindowDimensions} from 'react-native';
import {RNPlayerVideo} from './src/player';

function App(): JSX.Element {
  const {height} = useWindowDimensions();
  const [isFull, setIsFull] = useState(false);
  console.log('🚀 ~ file: App.tsx:15 ~ App ~ isFull:', isFull);
  // console.log('🚀 ~ file: App.tsx:14 ~ App ~ isFull:', isFull);
  // useEffect(() => {
  //   setTimeout(() => {
  //     setIsFull(!isFull);
  //   }, 12000);
  // }, [isFull]);
  const resizeMode = isFull ? 'cover' : 'contain';
  return (
    <RNPlayerVideo
      isFullScreen={isFull}
      style={{height: isFull ? height : 350}}
      onFullScreen={() => setIsFull(!isFull)}
      resizeMode={resizeMode}
    />
  );
}

export default App;
