import React, { useState } from 'react';
import { Platform, SafeAreaView, Text, TouchableOpacity } from 'react-native';
import { Video } from 'rn-media-player';
import { downloadFile } from './downloadFile';
import { directories } from '@kesha-antonov/react-native-background-downloader';

const SpeedsKey = 'Velocidades';
const Qualities = 'Qualidades';

const speedsValues = [
  { name: '0.5x', value: 0.5 },
  { name: 'Normal', value: 1.0 },
  { name: '1.5x', value: 1.5 },
  { name: '2.0x', value: 2.0 },
];

const qualitiesValues = [
  {
    name: 'Baixa',
    value: 'https://content.jwplatform.com/videos/ijHnL627-VIgN1lMW.mp4',
  },
  {
    name: 'Média',
    value: 'https://content.jwplatform.com/videos/ijHnL627-zZbIuxVJ.mp4',
  },
  {
    name: 'Alta',
    value: 'https://content.jwplatform.com/videos/ijHnL627-aoHq8DIe.mp4',
  },
];

function App(): JSX.Element {
  // const navigation = useNavigation();
  const [url, setUrl] = useState(
    'https://content.jwplatform.com/videos/ijHnL627-zZbIuxVJ.mp4'
  );
  const [rate, setRate] = useState(1);
  const [playbackQuality, setPlaybackQuality] = useState('');

  let downloadedUrl =
    Platform.OS === 'android'
      ? `file://${directories.documents}/file.mp4`
      : url;

  return (
    <SafeAreaView style={{ flex: 1 }}>
      <Video
        source={{
          url: downloadedUrl,
          metadata: { title: 'Sintel', artist: 'Google' },
          startTime: 30,
        }}
        thumbnails={{ isEnabled: true, sourceUrl: downloadedUrl }}
        style={{
          height: 375,
          backgroundColor: 'black',
        }}
        rate={rate}
        autoPlay={true}
        changeQualityUrl={playbackQuality}
        entersFullScreenWhenPlaybackBegins
        tapToSeek={{
          value: 15,
          suffixLabel: 'segundos',
        }}
        menus={{
          [SpeedsKey]: { data: speedsValues, initialItemSelected: 'Normal' },
          [Qualities]: {
            data: qualitiesValues,
            initialItemSelected: qualitiesValues[0]?.name as string,
          },
        }}
        // onFullscreen={({ nativeEvent }) => {
        //   console.log('fullscreen', nativeEvent);
        // }}
        // onMenuItemSelected={({ nativeEvent }) => {
        //   if (nativeEvent.name === SpeedsKey) {
        //     setRate(nativeEvent.value);
        //   }
        //   if (nativeEvent.name === Qualities) {
        //     setPlaybackQuality(nativeEvent.value);
        //   }
        // }}
        // onVideoProgress={({ nativeEvent }) => {
        //   console.log('video progress', nativeEvent);
        // }}
        // onPlayPause={(event) => console.log(event.nativeEvent.isPlaying)}
        // onMediaRouter={(event) => console.log(event.nativeEvent.isActive)}
        // onSeekBar={(event) => {
        //   console.log(event.nativeEvent);
        // }}
        //-------

        // onCompleted={({ nativeEvent: { completed } }) => console.log(completed)}
        // onReady={({ nativeEvent }) => console.log(nativeEvent)}
        // onPinchZoom={({ nativeEvent }) => console.log(nativeEvent.currentZoom)}
        // onBuffer={(e) =>
        //   console.log(`BUFFER STARTED ${JSON.stringify(e.nativeEvent)}`)
        // }
        // onError={(e) => console.log('native Error', e.nativeEvent)}
        // resizeMode={EResizeMode.Contain}
        // screenBehavior={{
        //   autoEnterFullscreenOnLandscape: false,
        //   autoOrientationOnFullscreen: false,
        // }}
        // lockControls={true}
        controlsStyles={
          {
            // loading: {
            //   color: '#cab9d1',
            // },
            // playback: {
            //   color: '#a90ee6',
            // },
            // seekSlider: {
            //   maximumTrackColor: '#f2f2f2',
            //   minimumTrackColor: '#890cba',
            //   seekableTintColor: '#df3030',
            //   thumbImageColor: '#a90ee6',
            // thumbnailBorderColor: '#a90ee6',
            // thumbnailTimeCodeColor: '#a90ee6',
            // },
            // timeCodes: {
            //   currentTimeColor: '#f3e9f7',
            //   durationColor: '#1a161c',
            //   slashColor: '#a90ee6',
            // },
            // menus: {
            //   color: '#a90ee6',
            // },
            // fullScreen: {
            //   color: '#a90ee6',
            // },
            // download: {
            //   color: '#696969',
            //   progressBarColor: '#908c91',
            //   progressBarFillColor: '#0df85f',
            //   messageDelete: 'Delete',
            //   messageDownload: 'Download',
            //   labelDelete: 'Delete',
            //   labelCancel: 'Cancel',
            //   labelDownload: 'Download',
            // },
            // toast: {
            //   // label: 'Video baixado com sucesso',
            //   // backgroundColor: '#0df85f',
            //   // labelColor: '#ffff',
            // },
            // header: {
            //   leftButtonColor: 'rgba(255,255,255,1)',
            //   titleColor: '#d71e1e',
            // },
          }
        }
      />
      {Platform.OS === 'android' && (
        <TouchableOpacity
          style={{ height: 50, backgroundColor: 'red' }}
          onPress={() => downloadFile(url)}
        >
          <Text style={{}}>Baixar Arquivo</Text>
        </TouchableOpacity>
      )}
    </SafeAreaView>
  );
}

export default App;

/**
 *     url: 'https://content.jwplatform.com/videos/MGAxJ46m-fQPeQtU3.mp4',
    title: 'Sample Video',
    startTime: 35,
    type: 'video/mp4',
    duration: 600,
    thumbnails: [
      'https://example.com/thumb1.jpg',
      'https://example.com/thumb2.jpg'
    ],
    poster: 'https://example.com/poster.jpg',
    subtitles: [
      { src: 'https://example.com/subtitles-en.vtt', language: 'en', label: 'English' }
    ],
    drm: { licenseUrl: 'https://drm.example.com/license' }
 */
