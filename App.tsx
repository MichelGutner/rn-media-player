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
  const [isFull, setIsFull] = useState(false);
  console.log('🚀 ~ App ~ isFull:', isFull);
  const resizeMode = isFull ? 'cover' : 'contain';

  return (
    <View>
      <RNPlayerVideo
        style={{height: 350, overflow: 'hidden'}}
        onFullScreen={e => setIsFull(e)}
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
