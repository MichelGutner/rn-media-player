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
  const resizeMode = isFull ? 'cover' : 'contain';

  return (
    <View>
      <RNPlayerVideo
        source={{
          url: 'https://content.jwplatform.com/videos/MGAxJ46m-zZbIuxVJ.mp4',
          videoTile: 'testing',
        }}
        // source={{
        //   url: 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        //   videoTile: 'testing',
        // }}
        style={{height: 300}}
        onFullScreen={e => setIsFull(e)}
        // resizeMode={resizeMode}
        paused={false}
        startTime={0}
        enterInFullScreenWhenDeviceRotated={true}
        autoPlay={true}
        loop={false}
      />
      <TouchableOpacity onPress={() => console.log('oi')}>
        <Text>Olá Mundo</Text>
      </TouchableOpacity>
    </View>
  );
}

export default App;
