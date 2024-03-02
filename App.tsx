/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, {useState} from 'react';
import {
  Button,
  SafeAreaView,
  Text,
  TouchableOpacity,
  View,
  useWindowDimensions,
} from 'react-native';
import {RNPlayerVideo} from './src/player';

function App(): JSX.Element {
  const {height} = useWindowDimensions();
  const [isFull, setIsFull] = useState(false);

  // useEffect(() => {
  //   setTimeout(() => {
  //     setIsFull(!isFull);
  //   }, 12000);
  // }, [isFull]);
  const resizeMode = isFull ? 'cover' : 'contain';
  return (
    <View style={{backgroundColor: 'blue', zIndex: 99999}}>
      <RNPlayerVideo
        isFullScreen={isFull}
        // style={{height}}
        style={{height: 350}}
        onFullScreen={() => setIsFull(!isFull)}
        resizeMode={resizeMode}
        paused={false}
        startTime={4}
        enterInFullScreenWhenDeviceRotated={true}
      />
      <TouchableOpacity onPress={() => console.log('oi')}>
        <Text>Olá Mundo</Text>
      </TouchableOpacity>
    </View>
  );
}

export default App;
